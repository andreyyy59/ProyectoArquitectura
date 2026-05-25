<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncConflict extends Model
{
    protected $fillable = [
        'sync_event_id', 'entity_type', 'entity_id',
        'client_payload', 'server_payload', 'resolution_strategy',
        'resolution_result', 'resolved_by', 'resolved_at',
    ];

    protected $casts = [
        'client_payload' => 'array',
        'server_payload' => 'array',
        'resolution_result' => 'array',
        'resolved_at' => 'datetime',
    ];

    public function event()
    {
        return $this->belongsTo(SyncEvent::class, 'sync_event_id');
    }

    public function resolveWithLastWriteWins(): array
    {
        $clientTime = strtotime($this->event->client_timestamp);
        $serverTime = strtotime($this->event->server_timestamp ?? 'now');

        $winner = $clientTime >= $serverTime ? 'CLIENT' : 'SERVER';
        $winningPayload = $winner === 'CLIENT' ? $this->client_payload : $this->server_payload;

        $this->update([
            'resolution_strategy' => 'LAST_WRITE_WINS',
            'resolution_result' => [
                'winner' => $winner,
                'winning_payload' => $winningPayload,
                'resolved_at' => now()->toIso8601String(),
            ],
            'resolved_by' => 'AUTOMATIC',
            'resolved_at' => now(),
        ]);

        return $winningPayload;
    }
}
