<?php

namespace EduConnect\Contracts;

/**
 * Define el contrato del protocolo de sincronización en 5 fases
 * para el Offline Sync Engine (MS-04).
 */
interface SyncProtocolContract
{
    /**
     * Fase 1: Detección — El nodo detecta disponibilidad de red
     * y evalúa si debe iniciar sincronización.
     */
    public function detectConnectivityWindow(): array;

    /**
     * Fase 2: Handshake — Intercambio de metadatos entre el Edge Node y el Cloud.
     * Determina las versiones actuales y qué cambios están pendientes.
     */
    public function handshake(int $edgeNodeId, array $nodeManifest): array;

    /**
     * Fase 3: Descarga Delta — El Edge Node recibe solo los cambios
     * incrementales desde el último checkpoint.
     */
    public function downloadDelta(int $edgeNodeId, string $entityType, array $checkpoint): array;

    /**
     * Fase 4: Subida de Cambios — El Edge Node envía los cambios
     * locales pendientes hacia el servidor.
     */
    public function uploadChanges(int $edgeNodeId, array $pendingChanges): array;

    /**
     * Fase 5: Resolución de Conflictos — Aplica estrategia Last-Write-Wins (LWW)
     * para resolver conflictos entre datos locales y remotos.
     */
    public function resolveConflicts(string $entityType, array $conflicts): array;
}
