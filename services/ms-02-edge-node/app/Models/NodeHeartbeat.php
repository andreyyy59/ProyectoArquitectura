<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NodeHeartbeat extends Model
{
    protected $table = 'node_heartbeats';

    protected $fillable = [
        'edge_node_id', 'status', 'latency_ms', 'cpu_usage_percent',
        'ram_usage_percent', 'storage_usage_percent', 'active_users_count',
        'bandwidth_kbps', 'checked_at',
    ];

    protected $casts = [
        'checked_at' => 'datetime',
    ];

    public function edgeNode()
    {
        return $this->belongsTo(EdgeNode::class, 'edge_node_id');
    }
}
