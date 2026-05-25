<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncEvent extends Model
{
    protected $fillable = [
        'sync_batch_id', 'entity_type', 'entity_id', 'operation',
        'payload', 'payload_hash', 'client_timestamp', 'server_timestamp',
        'conflict_resolution', 'is_synced', 'synced_at',
    ];

    protected $casts = [
        'payload' => 'array',
        'client_timestamp' => 'datetime',
        'server_timestamp' => 'datetime',
        'synced_at' => 'datetime',
        'is_synced' => 'boolean',
    ];

    public function batch()
    {
        return $this->belongsTo(SyncBatch::class, 'sync_batch_id');
    }

    public function conflict()
    {
        return $this->hasOne(SyncConflict::class, 'sync_event_id');
    }

    public function scopeUnsynced($query)
    {
        return $query->where('is_synced', false);
    }

    public function scopeByEntity($query, string $type, string $id)
    {
        return $query->where('entity_type', $type)->where('entity_id', $id);
    }

    public function markSynced(): void
    {
        $this->update([
            'is_synced' => true,
            'synced_at' => now(),
        ]);
    }
}
