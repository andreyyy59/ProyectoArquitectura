<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EdgeNode extends Model
{
    protected $table = 'edge_nodes';

    protected $fillable = [
        'uuid', 'name', 'location_lat', 'location_lng', 'municipality', 'department',
        'node_type', 'ip_address', 'mac_address', 'storage_capacity_mb', 'storage_used_mb',
        'cpu_cores', 'ram_mb', 'status', 'last_heartbeat_at', 'last_sync_at',
        'parent_node_id', 'config_json', 'is_active',
    ];

    protected $casts = [
        'location_lat' => 'decimal:7',
        'location_lng' => 'decimal:7',
        'config_json' => 'array',
        'last_heartbeat_at' => 'datetime',
        'last_sync_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function heartbeats()
    {
        return $this->hasMany(NodeHeartbeat::class, 'edge_node_id');
    }

    public function syncWindows()
    {
        return $this->hasMany(NodeSyncWindow::class, 'edge_node_id');
    }

    public function parent()
    {
        return $this->belongsTo(self::class, 'parent_node_id');
    }

    public function children()
    {
        return $this->hasMany(self::class, 'parent_node_id');
    }

    public function isOnline(): bool
    {
        return $this->status === 'ONLINE';
    }

    public function markHeartbeat(array $metrics): void
    {
        $this->heartbeats()->create([
            'status' => $metrics['status'] ?? 'ONLINE',
            'latency_ms' => $metrics['latency_ms'] ?? 0,
            'cpu_usage_percent' => $metrics['cpu_usage_percent'] ?? 0,
            'ram_usage_percent' => $metrics['ram_usage_percent'] ?? 0,
            'storage_usage_percent' => $metrics['storage_usage_percent'] ?? 0,
            'active_users_count' => $metrics['active_users_count'] ?? 0,
            'bandwidth_kbps' => $metrics['bandwidth_kbps'] ?? 0,
        ]);

        $this->update([
            'status' => $metrics['status'] ?? 'ONLINE',
            'last_heartbeat_at' => now(),
        ]);
    }
}
