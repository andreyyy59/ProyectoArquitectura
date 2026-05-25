<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EdgeNode;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class EdgeNodeController extends Controller
{
    public function index(Request $request)
    {
        $nodes = EdgeNode::withCount('heartbeats', 'children')
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->when($request->department, fn($q, $d) => $q->where('department', $d))
            ->when($request->active !== null, fn($q) => $q->where('is_active', $request->boolean('active')))
            ->paginate($request->per_page ?? 20);

        return $this->success($nodes);
    }

    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location_lat' => 'nullable|numeric',
            'location_lng' => 'nullable|numeric',
            'municipality' => 'nullable|string|max:255',
            'department' => 'nullable|string|max:255',
            'node_type' => 'required|in:REGIONAL,LOCAL,SCHOOL',
            'ip_address' => 'nullable|string|max:45',
            'storage_capacity_mb' => 'nullable|integer',
            'cpu_cores' => 'nullable|integer',
            'ram_mb' => 'nullable|integer',
            'parent_node_uuid' => 'nullable|string|exists:edge_nodes,uuid',
        ]);

        if ($validated['parent_node_uuid'] ?? null) {
            $parent = EdgeNode::where('uuid', $validated['parent_node_uuid'])->first();
            $validated['parent_node_id'] = $parent->id;
        }

        $validated['uuid'] = (string) Str::uuid();

        $node = EdgeNode::create($validated);

        return $this->success($node->fresh(), 201);
    }

    public function show($uuid)
    {
        $node = EdgeNode::with('heartbeats' => fn($q) => $q->latest()->limit(10))
            ->with('syncWindows')
            ->with('children')
            ->with('parent')
            ->where('uuid', $uuid)
            ->firstOrFail();

        return $this->success($node);
    }

    public function update(Request $request, $uuid)
    {
        $node = EdgeNode::where('uuid', $uuid)->firstOrFail();

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'ip_address' => 'sometimes|string|max:45',
            'storage_capacity_mb' => 'sometimes|integer',
            'cpu_cores' => 'sometimes|integer',
            'ram_mb' => 'sometimes|integer',
            'config_json' => 'sometimes|array',
            'is_active' => 'sometimes|boolean',
        ]);

        $node->update($validated);

        return $this->success($node->fresh());
    }

    public function heartbeat(Request $request, $uuid)
    {
        $node = EdgeNode::where('uuid', $uuid)->firstOrFail();

        $validated = $request->validate([
            'status' => 'required|in:ONLINE,OFFLINE,DEGRADED',
            'latency_ms' => 'required|integer|min:0',
            'cpu_usage_percent' => 'required|numeric|between:0,100',
            'ram_usage_percent' => 'required|numeric|between:0,100',
            'storage_usage_percent' => 'required|numeric|between:0,100',
            'active_users_count' => 'required|integer|min:0',
            'bandwidth_kbps' => 'required|integer|min:0',
        ]);

        $node->markHeartbeat($validated);

        return $this->success([
            'message' => 'Heartbeat registrado',
            'status' => $node->fresh()->status,
            'last_heartbeat_at' => $node->fresh()->last_heartbeat_at,
        ]);
    }

    public function status($uuid)
    {
        $node = EdgeNode::where('uuid', $uuid)->firstOrFail();

        return $this->success([
            'name' => $node->name,
            'status' => $node->status,
            'is_online' => $node->isOnline(),
            'last_heartbeat_at' => $node->last_heartbeat_at,
            'uptime' => $node->last_heartbeat_at?->diffInMinutes(),
            'storage_usage_percent' => $node->storage_capacity_mb > 0
                ? round(($node->storage_used_mb / $node->storage_capacity_mb) * 100, 2)
                : 0,
            'last_sync_at' => $node->last_sync_at,
        ]);
    }

    public function topology()
    {
        $nodes = EdgeNode::with('children:id,uuid,name,node_type,status,municipality,department,parent_node_id')
            ->whereNull('parent_node_id')
            ->get();

        return $this->success($nodes);
    }

    public function setSyncWindow(Request $request, $uuid)
    {
        $node = EdgeNode::where('uuid', $uuid)->firstOrFail();

        $validated = $request->validate([
            'window_start' => 'required|string',
            'window_end' => 'required|string',
            'day_of_week' => 'required|integer|between:1,7',
            'priority' => 'sometimes|in:LOW,MEDIUM,HIGH,CRITICAL',
        ]);

        $window = $node->syncWindows()->create($validated);

        return $this->success($window, 201);
    }
}
