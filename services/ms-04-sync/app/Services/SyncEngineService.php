<?php

namespace App\Services;

use App\Models\SyncBatch;
use App\Models\SyncEvent;
use App\Models\SyncConflict;
use EduConnect\Protocols\SyncProtocol;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Redis;

class SyncEngineService
{
    private SyncProtocol $protocol;

    public function __construct()
    {
        $this->protocol = new SyncProtocol();
    }

    /**
     * Inicia un nuevo batch de sincronización.
     */
    public function initiateSync(int $edgeNodeId, ?int $userId = null): SyncBatch
    {
        $batch = SyncBatch::create([
            'uuid' => (string) Str::uuid(),
            'edge_node_id' => $edgeNodeId,
            'user_id' => $userId,
            'batch_type' => 'DELTA',
            'status' => 'INITIATED',
            'phase' => 'DETECTION',
            'started_at' => now(),
        ]);

        $this->logToRedis("sync:batch:{$batch->id}", [
            'action' => 'INITIATED',
            'edge_node_id' => $edgeNodeId,
            'timestamp' => now()->toIso8601String(),
        ]);

        return $batch;
    }

    /**
     * Ejecuta la fase actual del batch y avanza.
     */
    public function executePhase(SyncBatch $batch): void
    {
        $batch->update(['status' => $batch->phase]);

        match ($batch->phase) {
            'DETECTION' => $this->runDetection($batch),
            'HANDSHAKE' => $this->runHandshake($batch),
            'DELTA_DOWNLOAD' => $this->runDeltaDownload($batch),
            'DELTA_UPLOAD' => $this->runDeltaUpload($batch),
            'CONFLICT_RESOLUTION' => $this->runConflictResolution($batch),
            default => throw new \RuntimeException("Fase desconocida: {$batch->phase}"),
        };
    }

    /**
     * Fase 1: Detección de ventana de conectividad.
     */
    private function runDetection(SyncBatch $batch): void
    {
        $detection = $this->protocol->detectConnectivityWindow();

        $batch->update([
            'phase' => 'HANDSHAKE',
            'status' => 'HANDSHAKE',
        ]);

        Cache::put("sync:detection:{$batch->id}", $detection, now()->addHour());
    }

    /**
     * Fase 2: Handshake — intercambio de manifiestos.
     */
    private function runHandshake(SyncBatch $batch): void
    {
        $nodeManifest = $this->getNodeManifest($batch->edge_node_id);
        $handshake = $this->protocol->handshake($batch->edge_node_id, $nodeManifest);

        $batch->update([
            'phase' => 'DELTA_DOWNLOAD',
            'status' => 'DOWNLOADING',
            'items_total' => $handshake['delta_plan']['total_delta_size'],
        ]);

        Cache::put("sync:handshake:{$batch->id}", $handshake, now()->addHour());
    }

    /**
     * Fase 3: Descarga delta de contenidos.
     */
    private function runDeltaDownload(SyncBatch $batch): void
    {
        $checkpoint = $this->getCheckpoint($batch->edge_node_id, 'contents');

        $delta = $this->protocol->downloadDelta(
            $batch->edge_node_id,
            'contents',
            $checkpoint
        );

        foreach ($delta['changes'] as $change) {
            $this->storeSyncEvent($batch, $change);
        }

        $batch->update([
            'phase' => 'DELTA_UPLOAD',
            'status' => 'UPLOADING',
            'items_processed' => count($delta['changes']),
        ]);
    }

    /**
     * Fase 4: Subida de cambios locales pendientes.
     */
    private function runDeltaUpload(SyncBatch $batch): void
    {
        $pendingChanges = SyncEvent::unsynced()
            ->where('sync_batch_id', $batch->id)
            ->get();

        $uploadResult = $this->protocol->uploadChanges(
            $batch->edge_node_id,
            $pendingChanges->toArray()
        );

        foreach ($uploadResult['conflicts'] as $conflict) {
            $this->storeConflict($batch, $conflict);
        }

        $batch->update([
            'phase' => 'CONFLICT_RESOLUTION',
            'status' => 'RESOLVING',
            'bytes_transferred' => $uploadResult['processed'],
        ]);
    }

    /**
     * Fase 5: Resolución de conflictos (Last-Write-Wins).
     */
    private function runConflictResolution(SyncBatch $batch): void
    {
        $conflicts = SyncConflict::whereHas('event', function ($q) use ($batch) {
            $q->where('sync_batch_id', $batch->id);
        })->get();

        foreach ($conflicts as $conflict) {
            $resolution = $conflict->resolveWithLastWriteWins();

            $this->logToRedis("sync:conflict:{$batch->id}", [
                'entity' => $conflict->entity_type,
                'entity_id' => $conflict->entity_id,
                'resolution' => 'LAST_WRITE_WINS',
                'winner' => $resolution['winner'],
            ]);
        }

        SyncEvent::where('sync_batch_id', $batch->id)
            ->where('is_synced', false)
            ->update(['is_synced' => true, 'synced_at' => now()]);

        $batch->complete();

        $this->updateCheckpoint($batch->edge_node_id, $batch->id);
    }

    /**
     * Procesa un evento individual (llamado desde el job).
     */
    public function processSingleEvent(SyncEvent $event): void
    {
        $payload = $event->payload;

        $resolved = match ($event->operation) {
            'CREATE' => $this->applyCreate($event->entity_type, $payload),
            'UPDATE' => $this->applyUpdate($event->entity_type, $event->entity_id, $payload),
            'DELETE' => $this->applyDelete($event->entity_type, $event->entity_id),
            default => throw new \RuntimeException("Operación desconocida: {$event->operation}"),
        };

        if ($resolved) {
            $event->markSynced();
        }
    }

    // ─── Métodos auxiliares ────────────────────────────────────

    private function getNodeManifest(int $edgeNodeId): array
    {
        return Cache::get("node:manifest:{$edgeNodeId}", [
            'contents_version' => 0,
            'users_version' => 0,
            'progress_version' => 0,
        ]);
    }

    private function getCheckpoint(int $edgeNodeId, string $entityType): array
    {
        return Cache::get("sync:checkpoint:{$edgeNodeId}:{$entityType}", [
            'last_id' => 0,
            'timestamp' => now()->subMonth()->toIso8601String(),
        ]);
    }

    private function updateCheckpoint(int $edgeNodeId, int $batchId): void
    {
        $cacheKey = "sync:checkpoint:{$edgeNodeId}:last_batch";
        Cache::put($cacheKey, $batchId, now()->addDays(7));
    }

    private function storeSyncEvent(SyncBatch $batch, array $change): SyncEvent
    {
        $payload = $change['payload'] ?? $change;
        return SyncEvent::create([
            'sync_batch_id' => $batch->id,
            'entity_type' => $change['entity_type'] ?? 'unknown',
            'entity_id' => $change['entity_id'] ?? '0',
            'operation' => $change['operation'] ?? 'UPDATE',
            'payload' => $payload,
            'payload_hash' => sha1(json_encode($payload)),
            'client_timestamp' => $change['client_timestamp'] ?? now(),
        ]);
    }

    private function storeConflict(SyncBatch $batch, array $conflict): SyncConflict
    {
        $event = SyncEvent::create([
            'sync_batch_id' => $batch->id,
            'entity_type' => $conflict['entity_type'],
            'entity_id' => $conflict['entity_id'],
            'operation' => 'UPDATE',
            'payload' => $conflict,
            'payload_hash' => sha1(json_encode($conflict)),
            'client_timestamp' => now(),
            'conflict_resolution' => 'PENDING',
            'is_synced' => false,
        ]);

        return SyncConflict::create([
            'sync_event_id' => $event->id,
            'entity_type' => $conflict['entity_type'],
            'entity_id' => $conflict['entity_id'],
            'client_payload' => $conflict,
            'server_payload' => [],
            'resolution_strategy' => 'LAST_WRITE_WINS',
        ]);
    }

    private function applyCreate(string $entityType, array $payload): bool
    {
        // Delega al servicio correspondiente según entity_type
        Redis::publish('sync:events', json_encode([
            'action' => 'CREATE',
            'type' => $entityType,
            'payload' => $payload,
        ]));
        return true;
    }

    private function applyUpdate(string $entityType, string $entityId, array $payload): bool
    {
        Redis::publish('sync:events', json_encode([
            'action' => 'UPDATE',
            'type' => $entityType,
            'id' => $entityId,
            'payload' => $payload,
        ]));
        return true;
    }

    private function applyDelete(string $entityType, string $entityId): bool
    {
        Redis::publish('sync:events', json_encode([
            'action' => 'DELETE',
            'type' => $entityType,
            'id' => $entityId,
        ]));
        return true;
    }

    private function logToRedis(string $key, array $data): void
    {
        Redis::rpush($key, json_encode($data));
        Redis::expire($key, 86400);
    }
}
