<?php

namespace App\Jobs;

use App\Models\SyncEvent;
use App\Services\SyncEngineService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ProcessDeltaUpload implements ShouldQueue
{
    use Queueable;

    public function __construct(public SyncEvent $event) {}

    public function handle(SyncEngineService $engine): void
    {
        try {
            $engine->processSingleEvent($this->event);
        } catch (\Throwable $e) {
            $this->fail($e);
        }
    }

    public function tags(): array
    {
        return ['sync:delta', "event:{$this->event->id}"];
    }
}
