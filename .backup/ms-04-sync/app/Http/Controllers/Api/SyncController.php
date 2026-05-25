<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SyncBatch;
use App\Models\SyncEvent;
use App\Jobs\ProcessSyncBatch;
use App\Services\SyncEngineService;
use Illuminate\Http\Request;

class SyncController extends Controller
{
    public function __construct(private SyncEngineService $engine) {}

    /**
     * Inicia el proceso de sincronización en 5 fases.
     */
    public function initiate(Request $request)
    {
        $validated = $request->validate([
            'edge_node_id' => 'required|integer',
            'user_id' => 'nullable|integer',
            'batch_type' => 'nullable|in:FULL,DELTA,HEARTBEAT',
        ]);

        $batch = $this->engine->initiateSync(
            $validated['edge_node_id'],
            $validated['user_id'] ?? null
        );

        ProcessSyncBatch::dispatch($batch);

        return $this->success([
            'batch_uuid' => $batch->uuid,
            'phase' => $batch->phase,
            'status' => $batch->status,
            'started_at' => $batch->started_at,
        ], 201);
    }

    /**
     * Fase 2: Handshake — recibe manifiesto del Edge Node.
     */
    public function handshake(Request $request)
    {
        $validated = $request->validate([
            'batch_uuid' => 'required|string|exists:sync_batches,uuid',
            'node_manifest' => 'required|array',
        ]);

        $batch = SyncBatch::where('uuid', $validated['batch_uuid'])->firstOrFail();

        $result = $this->engine->executePhase($batch);

        return $this->success([
            'batch_uuid' => $batch->uuid,
            'phase' => $batch->phase,
            'server_manifest' => [
                'contents_version' => 3,
                'users_version' => 5,
                'progress_version' => 2,
            ],
        ]);
    }

    /**
     * Fase 3: Descarga delta de contenidos.
     */
    public function downloadDelta(Request $request)
    {
        $validated = $request->validate([
            'edge_node_id' => 'required|integer',
            'entity_type' => 'required|string',
            'last_sync_id' => 'nullable|integer',
        ]);

        $changes = SyncEvent::where('is_synced', false)
            ->where('entity_type', $validated['entity_type'])
            ->when($validated['last_sync_id'] ?? null, fn($q, $id) => $q->where('id', '>', $id))
            ->limit(50)
            ->get();

        return $this->success([
            'changes' => $changes,
            'count' => $changes->count(),
            'has_more' => $changes->count() >= 50,
        ]);
    }

    /**
     * Fase 4: Recibe y procesa cambios subidos por el Edge Node.
     */
    public function uploadChanges(Request $request)
    {
        $validated = $request->validate([
            'edge_node_id' => 'required|integer',
            'changes' => 'required|array',
            'changes.*.entity_type' => 'required|string',
            'changes.*.entity_id' => 'required|string',
            'changes.*.operation' => 'required|in:CREATE,UPDATE,DELETE',
            'changes.*.payload' => 'required|array',
            'changes.*.client_timestamp' => 'required|date',
        ]);

        $batch = SyncBatch::create([
            'uuid' => \Illuminate\Support\Str::uuid(),
            'edge_node_id' => $validated['edge_node_id'],
            'batch_type' => 'DELTA',
            'status' => 'UPLOADING',
            'phase' => 'DELTA_UPLOAD',
            'items_total' => count($validated['changes']),
            'started_at' => now(),
        ]);

        $conflicts = [];
        $processed = 0;

        foreach ($validated['changes'] as $change) {
            try {
                $event = SyncEvent::create([
                    'sync_batch_id' => $batch->id,
                    'entity_type' => $change['entity_type'],
                    'entity_id' => $change['entity_id'],
                    'operation' => $change['operation'],
                    'payload' => $change['payload'],
                    'payload_hash' => sha1(json_encode($change['payload'])),
                    'client_timestamp' => $change['client_timestamp'],
                    'server_timestamp' => now(),
                    'conflict_resolution' => 'PENDING',
                ]);
                $processed++;
            } catch (\Throwable $e) {
                $conflicts[] = [
                    'entity' => $change['entity_type'],
                    'entity_id' => $change['entity_id'],
                    'error' => $e->getMessage(),
                ];
            }
        }

        $batch->update([
            'items_processed' => $processed,
            'status' => $conflicts ? 'RESOLVING' : 'COMPLETED',
            'phase' => $conflicts ? 'CONFLICT_RESOLUTION' : 'COMPLETED',
        ]);

        return $this->success([
            'batch_uuid' => $batch->uuid,
            'processed' => $processed,
            'conflicts' => count($conflicts),
            'conflict_details' => $conflicts,
        ]);
    }

    /**
     * Fase 5: Resolución de conflictos.
     */
    public function resolveConflicts(Request $request)
    {
        $validated = $request->validate([
            'batch_uuid' => 'required|string|exists:sync_batches,uuid',
        ]);

        $batch = SyncBatch::where('uuid', $validated['batch_uuid'])->firstOrFail();
        $this->engine->executePhase($batch);

        return $this->success([
            'batch_uuid' => $batch->uuid,
            'status' => $batch->status,
            'completed_at' => $batch->completed_at,
        ]);
    }

    /**
     * Consulta el estado de un batch de sincronización.
     */
    public function status(string $batchUuid)
    {
        $batch = SyncBatch::where('uuid', $batchUuid)->withCount('events')->firstOrFail();

        return $this->success([
            'uuid' => $batch->uuid,
            'phase' => $batch->phase,
            'status' => $batch->status,
            'items_total' => $batch->items_total,
            'items_processed' => $batch->items_processed,
            'bytes_transferred' => $batch->bytes_transferred,
            'started_at' => $batch->started_at,
            'completed_at' => $batch->completed_at,
            'events_count' => $batch->events_count,
        ]);
    }

    /**
     * Consulta cambios pendientes para un nodo específico.
     */
    public function pendingChanges(int $edgeNodeId)
    {
        $batches = SyncBatch::byNode($edgeNodeId)->pending()->get();
        $events = SyncEvent::unsynced()
            ->whereIn('sync_batch_id', $batches->pluck('id'))
            ->limit(100)
            ->get();

        return $this->success([
            'edge_node_id' => $edgeNodeId,
            'pending_batches' => $batches->count(),
            'pending_events' => $events->count(),
            'events' => $events,
        ]);
    }

    /**
     * Almacena eventos de sincronización offline.
     */
    public function storeEvents(Request $request)
    {
        $validated = $request->validate([
            'edge_node_id' => 'required|integer',
            'events' => 'required|array',
            'events.*.entity_type' => 'required|string',
            'events.*.entity_id' => 'required|string',
            'events.*.operation' => 'required|in:CREATE,UPDATE,DELETE',
            'events.*.payload' => 'required|array',
        ]);

        $batch = SyncBatch::create([
            'uuid' => \Illuminate\Support\Str::uuid(),
            'edge_node_id' => $validated['edge_node_id'],
            'batch_type' => 'DELTA',
            'status' => 'INITIATED',
            'phase' => 'DETECTION',
            'items_total' => count($validated['events']),
            'started_at' => now(),
        ]);

        foreach ($validated['events'] as $event) {
            SyncEvent::create([
                'sync_batch_id' => $batch->id,
                'entity_type' => $event['entity_type'],
                'entity_id' => $event['entity_id'],
                'operation' => $event['operation'],
                'payload' => $event['payload'],
                'payload_hash' => sha1(json_encode($event['payload'])),
                'client_timestamp' => $event['client_timestamp'] ?? now(),
                'conflict_resolution' => 'PENDING',
            ]);
        }

        ProcessSyncBatch::dispatch($batch);

        return $this->success([
            'batch_uuid' => $batch->uuid,
            'events_stored' => count($validated['events']),
            'status' => 'queued',
        ], 201);
    }

    /**
     * Obtiene el último checkpoint de sincronización.
     */
    public function checkpoint(int $edgeNodeId)
    {
        $lastBatch = SyncBatch::byNode($edgeNodeId)
            ->where('status', 'COMPLETED')
            ->latest()
            ->first();

        return $this->success([
            'edge_node_id' => $edgeNodeId,
            'last_batch_id' => $lastBatch?->id,
            'last_sync_at' => $lastBatch?->completed_at,
        ]);
    }
}
