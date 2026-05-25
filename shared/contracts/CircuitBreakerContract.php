<?php

namespace EduConnect\Contracts;

/**
 * Contrato para el patrón Circuit Breaker.
 * Permite que los Edge Nodes operen de forma autónoma
 * cuando el Cloud no responde.
 */
interface CircuitBreakerContract
{
    /**
     * Estados posibles del Circuit Breaker.
     */
    public const STATE_CLOSED = 'CLOSED';
    public const STATE_OPEN = 'OPEN';
    public const STATE_HALF_OPEN = 'HALF_OPEN';

    /**
     * Verifica si el circuito está cerrado (servicio disponible).
     */
    public function isAvailable(): bool;

    /**
     * Registra un éxito y resetea el contador de fallos.
     */
    public function recordSuccess(): void;

    /**
     * Registra un fallo. Si se supera el umbral, abre el circuito.
     */
    public function recordFailure(): void;

    /**
     * Obtiene el estado actual del circuito.
     */
    public function getState(): string;

    /**
     * Intenta restaurar el circuito (half-open).
     */
    public function attemptReset(): bool;
}
