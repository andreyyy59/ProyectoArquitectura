<?php

namespace App\Jobs;

use App\Models\SyncBatch;
use App\Models\SyncEvent;
use App\Services\SyncEngineService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\Middleware\ThrottlesExceptions;

class ProcessSyncBatch implements ShouldQueue
{
    use Queueable;

    public function __construct(public SyncBatch $batch) {}

    public function handle(SyncEngineService $engine): void
    {
        try {
            $engine->executePhase($this->batch);

            if ($this->batch->phase !== 'CONFLICT_RESOLUTION') {
                dispatch(new ProcessSyncBatch($this->batch->fresh()))
                    ->delay(now()->addSeconds(2));
            }
        } catch (\Throwable $e) {
            $this->batch->fail($e->getMessage());
            throw $e;
        }
    }

    public function middleware(): array
    {
        return [
            new ThrottlesExceptions(3, 5),
        ];
    }

    public function tags(): array
    {
        return ['sync', "batch:{$this->batch->id}"];
    }
}
