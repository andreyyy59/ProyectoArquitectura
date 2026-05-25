<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncBatch extends Model
{
    protected $fillable = [
        'uuid', 'edge_node_id', 'user_id', 'batch_type', 'status',
        'phase', 'items_total', 'items_processed', 'bytes_transferred',
        'started_at', 'completed_at', 'error_message',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'items_total' => 'integer',
        'items_processed' => 'integer',
    ];

    public const PHASES = [
        'DETECTION', 'HANDSHAKE', 'DELTA_DOWNLOAD', 'DELTA_UPLOAD', 'CONFLICT_RESOLUTION',
    ];

    public function events()
    {
        return $this->hasMany(SyncEvent::class);
    }

    public function scopePending($query)
    {
        return $query->whereNotIn('status', ['COMPLETED', 'FAILED']);
    }

    public function scopeByNode($query, $nodeId)
    {
        return $query->where('edge_node_id', $nodeId);
    }

    public function advancePhase(): bool
    {
        $phases = self::PHASES;
        $currentIndex = array_search($this->phase, $phases);

        if ($currentIndex !== false && $currentIndex < count($phases) - 1) {
            $this->update(['phase' => $phases[$currentIndex + 1]]);
            return true;
        }

        return false;
    }

    public function complete(): void
    {
        $this->update([
            'status' => 'COMPLETED',
            'completed_at' => now(),
            'phase' => 'CONFLICT_RESOLUTION',
        ]);
    }

    public function fail(string $error): void
    {
        $this->update([
            'status' => 'FAILED',
            'error_message' => $error,
            'completed_at' => now(),
        ]);
    }

    public function incrementProcessed(int $count = 1): void
    {
        $this->increment('items_processed', $count);
    }
}
