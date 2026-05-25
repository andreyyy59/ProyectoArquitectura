<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use EduConnect\Protocols\CircuitBreaker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ConnectivityController extends Controller
{
    public function heartbeat(Request $request)
    {
        $validated = $request->validate([
            'edge_node_id' => 'required|integer',
            'status' => 'required|in:ONLINE,OFFLINE,DEGRADED',
            'latency_ms' => 'required|integer|min:0',
            'bandwidth_kbps' => 'required|integer|min:0',
        ]);

        $nodeId = $validated['edge_node_id'];
        $cacheKey = "connectivity:node:{$nodeId}";

        $current = Cache::get($cacheKey, [
            'heartbeats' => [],
            'avg_latency' => 0,
            'uptime_percent' => 100,
            'last_seen' => null,
        ]);

        $heartbeat = [
            'status' => $validated['status'],
            'latency_ms' => $validated['latency_ms'],
            'bandwidth_kbps' => $validated['bandwidth_kbps'],
            'timestamp' => now()->toIso8601String(),
        ];

        $current['heartbeats'][] = $heartbeat;
        $current['heartbeats'] = array_slice($current['heartbeats'], -50);
        $current['last_seen'] = now()->toIso8601String();
        $current['avg_latency'] = collect($current['heartbeats'])->avg('latency_ms');

        Cache::put($cacheKey, $current, now()->addHours(24));

        $shouldSync = $validated['status'] === 'ONLINE'
            && $validated['latency_ms'] < 1000
            && $validated['bandwidth_kbps'] > 100;

        return $this->success([
            'status' => 'recorded',
            'should_sync' => $shouldSync,
            'last_heartbeat' => $heartbeat,
            'avg_latency_ms' => round($current['avg_latency'], 2),
        ]);
    }

    public function nodeStatus(int $edgeNodeId)
    {
        $cacheKey = "connectivity:node:{$edgeNodeId}";
        $data = Cache::get($cacheKey);

        if (!$data) {
            return $this->error('Nodo no encontrado o sin heartbeat', 404);
        }

        $lastHeartbeat = end($data['heartbeats']);

        return $this->success([
            'edge_node_id' => $edgeNodeId,
            'current_status' => $lastHeartbeat['status'] ?? 'UNKNOWN',
            'avg_latency_ms' => round($data['avg_latency'], 2),
            'uptime_percent' => $this->calculateUptime($data['heartbeats']),
            'last_seen' => $data['last_seen'],
            'heartbeat_count' => count($data['heartbeats']),
            'connectivity_window' => $this->detectConnectivityWindow($data['heartbeats']),
        ]);
    }

    public function syncWindows(int $edgeNodeId)
    {
        $cacheKey = "connectivity:node:{$edgeNodeId}";
        $data = Cache::get($cacheKey);

        if (!$data) {
            return $this->success([
                'edge_node_id' => $edgeNodeId,
                'windows' => [],
            ]);
        }

        $windows = $this->calculateSyncWindows($data['heartbeats']);

        return $this->success([
            'edge_node_id' => $edgeNodeId,
            'windows' => $windows,
            'recommended_window' => $windows[0] ?? null,
        ]);
    }

    public function circuitBreakerStatus(string $serviceName)
    {
        $circuitBreaker = new CircuitBreaker(
            serviceName: $serviceName,
            threshold: (int) config('educonnect.circuit_breaker_threshold', 5),
            timeoutMs: (int) config('educonnect.circuit_breaker_timeout', 30000),
        );

        return $this->success($circuitBreaker->getMetrics());
    }

    public function networkMap()
    {
        $keys = Cache::get('connectivity:nodes', []);
        $nodes = [];

        foreach ($keys as $nodeId) {
            $data = Cache::get("connectivity:node:{$nodeId}");
            if ($data) {
                $last = end($data['heartbeats']);
                $nodes[] = [
                    'edge_node_id' => $nodeId,
                    'status' => $last['status'] ?? 'UNKNOWN',
                    'latency_ms' => $last['latency_ms'] ?? 0,
                    'last_seen' => $data['last_seen'],
                ];
            }
        }

        return $this->success([
            'total_nodes' => count($nodes),
            'online' => count(array_filter($nodes, fn($n) => $n['status'] === 'ONLINE')),
            'offline' => count(array_filter($nodes, fn($n) => $n['status'] === 'OFFLINE')),
            'nodes' => $nodes,
        ]);
    }

    private function calculateUptime(array $heartbeats): float
    {
        if (empty($heartbeats)) return 100;
        $online = count(array_filter($heartbeats, fn($h) => $h['status'] === 'ONLINE'));
        return round(($online / count($heartbeats)) * 100, 2);
    }

    private function detectConnectivityWindow(array $heartbeats): ?array
    {
        $recent = array_slice($heartbeats, -10);
        $online = array_filter($recent, fn($h) => $h['status'] === 'ONLINE' && $h['latency_ms'] < 1000);

        if (count($online) >= 3) {
            return [
                'available' => true,
                'quality' => 'GOOD',
                'avg_latency' => collect($online)->avg('latency_ms'),
            ];
        }

        return ['available' => false, 'quality' => 'POOR', 'avg_latency' => 9999];
    }

    private function calculateSyncWindows(array $heartbeats): array
    {
        if (empty($heartbeats)) return [];

        $byHour = [];
        foreach ($heartbeats as $h) {
            $hour = date('H', strtotime($h['timestamp']));
            if (!isset($byHour[$hour])) {
                $byHour[$hour] = ['total' => 0, 'online' => 0, 'avg_latency' => []];
            }
            $byHour[$hour]['total']++;
            if ($h['status'] === 'ONLINE') {
                $byHour[$hour]['online']++;
            }
            $byHour[$hour]['avg_latency'][] = $h['latency_ms'];
        }

        $windows = [];
        foreach ($byHour as $hour => $data) {
            $reliability = $data['total'] > 0 ? ($data['online'] / $data['total']) * 100 : 0;
            if ($reliability > 50) {
                $windows[] = [
                    'hour' => (int) $hour,
                    'reliability_percent' => round($reliability, 2),
                    'avg_latency_ms' => round(array_sum($data['avg_latency']) / count($data['avg_latency']), 2),
                ];
            }
        }

        usort($windows, fn($a, $b) => $b['reliability_percent'] <=> $a['reliability_percent']);

        return $windows;
    }
}
