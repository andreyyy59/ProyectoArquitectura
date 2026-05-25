<?php

namespace EduConnect\Protocols;

use EduConnect\Contracts\SyncProtocolContract;

/**
 * Implementación del protocolo de sincronización en 5 fases.
 *
 * Flujo:
 * 1. DETECTION   → Escaneo de red disponible
 * 2. HANDSHAKE   → Intercambio de manifiestos
 * 3. DELTA_DOWNLOAD → Descarga incremental
 * 4. DELTA_UPLOAD   → Subida de cambios locales
 * 5. CONFLICT_RESOLUTION → LWW resolution
 */
class SyncProtocol implements SyncProtocolContract
{
    private const PHASES = [
        'DETECTION',
        'HANDSHAKE',
        'DELTA_DOWNLOAD',
        'DELTA_UPLOAD',
        'CONFLICT_RESOLUTION',
    ];

    private array $state = [
        'current_phase' => 'DETECTION',
        'edge_node_id' => null,
        'batch_uuid' => null,
        'started_at' => null,
        'checkpoint' => [],
        'errors' => [],
    ];

    public function detectConnectivityWindow(): array
    {
        $this->state['current_phase'] = 'DETECTION';
        $this->state['started_at'] = now()->toIso8601String();

        return [
            'phase' => 'DETECTION',
            'available' => $this->pingCloud(),
            'latency_ms' => $this->measureLatency(),
            'bandwidth_kbps' => $this->estimateBandwidth(),
            'timestamp' => now()->toIso8601String(),
        ];
    }

    public function handshake(int $edgeNodeId, array $nodeManifest): array
    {
        $this->state['current_phase'] = 'HANDSHAKE';
        $this->state['edge_node_id'] = $edgeNodeId;

        $serverManifest = $this->getServerManifest($edgeNodeId);

        $deltaPlan = $this->computeDeltaPlan($nodeManifest, $serverManifest);

        return [
            'phase' => 'HANDSHAKE',
            'server_manifest' => $serverManifest,
            'delta_plan' => $deltaPlan,
            'requires_full_sync' => $deltaPlan['total_delta_size'] > 0,
            'timestamp' => now()->toIso8601String(),
        ];
    }

    public function downloadDelta(int $edgeNodeId, string $entityType, array $checkpoint): array
    {
        $this->state['current_phase'] = 'DELTA_DOWNLOAD';

        $changes = $this->getChangesSince($entityType, $checkpoint);

        return [
            'phase' => 'DELTA_DOWNLOAD',
            'entity_type' => $entityType,
            'changes' => $changes,
            'count' => count($changes),
            'new_checkpoint' => $this->buildNewCheckpoint($changes),
            'timestamp' => now()->toIso8601String(),
        ];
    }

    public function uploadChanges(int $edgeNodeId, array $pendingChanges): array
    {
        $this->state['current_phase'] = 'DELTA_UPLOAD';

        $results = [];
        $conflicts = [];

        foreach ($pendingChanges as $change) {
            try {
                $result = $this->applyChange($change);
                if ($result['conflict']) {
                    $conflicts[] = $result;
                }
                $results[] = $result;
            } catch (\Throwable $e) {
                $conflicts[] = [
                    'entity_type' => $change['entity_type'],
                    'entity_id' => $change['entity_id'],
                    'error' => $e->getMessage(),
                    'conflict' => true,
                ];
            }
        }

        return [
            'phase' => 'DELTA_UPLOAD',
            'processed' => count($results),
            'conflicts_found' => count($conflicts),
            'results' => $results,
            'conflicts' => $conflicts,
            'timestamp' => now()->toIso8601String(),
        ];
    }

    public function resolveConflicts(string $entityType, array $conflicts): array
    {
        $this->state['current_phase'] = 'CONFLICT_RESOLUTION';

        $resolved = [];
        foreach ($conflicts as $conflict) {
            $resolved[] = $this->lastWriteWins($conflict);
        }

        return [
            'phase' => 'CONFLICT_RESOLUTION',
            'strategy' => 'LAST_WRITE_WINS',
            'entity_type' => $entityType,
            'resolved' => $resolved,
            'timestamp' => now()->toIso8601String(),
        ];
    }

    // ─── Métodos privados de infraestructura ───────────────────

    private function pingCloud(): bool
    {
        // Simula ping al cloud central
        return true;
    }

    private function measureLatency(): int
    {
        // Simula medición de latencia
        return random_int(50, 500);
    }

    private function estimateBandwidth(): int
    {
        // Simula estimación de ancho de banda en kbps
        return random_int(100, 5000);
    }

    private function getServerManifest(int $edgeNodeId): array
    {
        // Obtiene del servidor el manifiesto actual de contenidos
        return [
            'contents_version' => 3,
            'users_version' => 5,
            'progress_version' => 2,
            'total_contents' => 120,
            'total_users' => 450,
            'last_sync_at' => now()->subHours(2)->toIso8601String(),
        ];
    }

    private function computeDeltaPlan(array $node, array $server): array
    {
        $deltas = [];
        foreach (['contents_version', 'users_version', 'progress_version'] as $key) {
            if (($node[$key] ?? 0) < ($server[$key] ?? 0)) {
                $deltas[$key] = [
                    'local' => $node[$key] ?? 0,
                    'remote' => $server[$key] ?? 0,
                    'needs_update' => true,
                ];
            }
        }
        return [
            'deltas' => $deltas,
            'total_delta_size' => count($deltas),
        ];
    }

    private function getChangesSince(string $entityType, array $checkpoint): array
    {
        // Consulta cambios desde el último checkpoint
        return [];
    }

    private function buildNewCheckpoint(array $changes): array
    {
        return [
            'last_id' => count($changes),
            'timestamp' => now()->toIso8601String(),
        ];
    }

    private function applyChange(array $change): array
    {
        // Aplica el cambio en la base de datos
        return [
            'entity_type' => $change['entity_type'],
            'entity_id' => $change['entity_id'],
            'success' => true,
            'conflict' => false,
        ];
    }

    private function lastWriteWins(array $conflict): array
    {
        $clientTime = strtotime($conflict['client_timestamp'] ?? 'now');
        $serverTime = strtotime($conflict['server_timestamp'] ?? 'now');

        $winner = $clientTime >= $serverTime ? 'CLIENT' : 'SERVER';

        return [
            'entity_type' => $conflict['entity_type'],
            'entity_id' => $conflict['entity_id'],
            'resolution' => 'LAST_WRITE_WINS',
            'winner' => $winner,
            'resolved_at' => now()->toIso8601String(),
        ];
    }
}
