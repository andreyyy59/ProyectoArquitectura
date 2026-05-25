<?php

namespace EduConnect\Protocols;

use EduConnect\Contracts\CircuitBreakerContract;

/**
 * Implementación del patrón Circuit Breaker.
 *
 * Protege al Edge Node de llamadas fallidas al Cloud.
 * Cuando el circuito se abre, el nodo opera en modo autónomo.
 */
class CircuitBreaker implements CircuitBreakerContract
{
    private string $state = self::STATE_CLOSED;
    private int $failureCount = 0;
    private int $successCount = 0;
    private ?int $lastFailureTime = null;
    private int $threshold;
    private int $timeoutMs;
    private int $halfOpenMaxSuccess = 3;
    private string $serviceName;

    public function __construct(
        string $serviceName,
        int $threshold = 5,
        int $timeoutMs = 30000
    ) {
        $this->serviceName = $serviceName;
        $this->threshold = $threshold;
        $this->timeoutMs = $timeoutMs;
    }

    public function isAvailable(): bool
    {
        if ($this->state === self::STATE_CLOSED) {
            return true;
        }

        if ($this->state === self::STATE_OPEN) {
            if ($this->hasTimeoutElapsed()) {
                $this->state = self::STATE_HALF_OPEN;
                $this->successCount = 0;
                return true;
            }
            return false;
        }

        return true;
    }

    public function recordSuccess(): void
    {
        $this->successCount++;
        $this->failureCount = 0;
        $this->lastFailureTime = null;

        if ($this->state === self::STATE_HALF_OPEN) {
            if ($this->successCount >= $this->halfOpenMaxSuccess) {
                $this->state = self::STATE_CLOSED;
            }
        }
    }

    public function recordFailure(): void
    {
        $this->failureCount++;
        $this->lastFailureTime = now()->getTimestamp() * 1000;

        if ($this->failureCount >= $this->threshold) {
            $this->state = self::STATE_OPEN;
        }
    }

    public function getState(): string
    {
        return $this->state;
    }

    public function attemptReset(): bool
    {
        if ($this->state === self::STATE_OPEN && $this->hasTimeoutElapsed()) {
            $this->state = self::STATE_HALF_OPEN;
            $this->successCount = 0;
            return true;
        }
        return false;
    }

    public function getServiceName(): string
    {
        return $this->serviceName;
    }

    public function getFailureCount(): int
    {
        return $this->failureCount;
    }

    public function getMetrics(): array
    {
        return [
            'service' => $this->serviceName,
            'state' => $this->state,
            'failure_count' => $this->failureCount,
            'success_count' => $this->successCount,
            'threshold' => $this->threshold,
            'timeout_ms' => $this->timeoutMs,
            'is_available' => $this->isAvailable(),
        ];
    }

    private function hasTimeoutElapsed(): bool
    {
        if ($this->lastFailureTime === null) {
            return true;
        }
        return (now()->getTimestamp() * 1000 - $this->lastFailureTime) >= $this->timeoutMs;
    }
}
