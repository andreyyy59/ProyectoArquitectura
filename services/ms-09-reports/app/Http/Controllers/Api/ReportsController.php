<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ReportsController extends Controller
{
    public function regionalSummary()
    {
        $summary = Cache::remember('reports:regional', 3600, function () {
            return [
                'total_students' => random_int(1000, 5000),
                'total_teachers' => random_int(50, 200),
                'total_nodes' => random_int(10, 50),
                'active_learning_paths' => random_int(200, 1000),
                'contents_delivered' => random_int(500, 2000),
                'avg_completion_rate' => round(random_int(40, 85) / 100, 2),
                'regions' => [
                    ['department' => 'Cauca', 'students' => 1200, 'nodes' => 8, 'completion_rate' => 0.72],
                    ['department' => 'Nariño', 'students' => 980, 'nodes' => 6, 'completion_rate' => 0.65],
                    ['department' => 'Chocó', 'students' => 750, 'nodes' => 5, 'completion_rate' => 0.58],
                    ['department' => 'La Guajira', 'students' => 620, 'nodes' => 4, 'completion_rate' => 0.61],
                    ['department' => 'Amazonas', 'students' => 450, 'nodes' => 3, 'completion_rate' => 0.55],
                ],
                'generated_at' => now()->toIso8601String(),
            ];
        });

        return $this->success($summary);
    }

    public function departmentDetail(string $department)
    {
        return $this->success([
            'department' => $department,
            'total_students' => random_int(100, 2000),
            'total_nodes' => random_int(2, 20),
            'municipalities' => [
                ['name' => "{$department} Norte", 'students' => 350, 'completion' => 0.75],
                ['name' => "{$department} Sur", 'students' => 280, 'completion' => 0.68],
                ['name' => "{$department} Centro", 'students' => 420, 'completion' => 0.71],
            ],
        ]);
    }

    public function municipalityDetail(string $municipality)
    {
        return $this->success([
            'municipality' => $municipality,
            'students' => random_int(20, 500),
            'teachers' => random_int(2, 20),
            'nodes' => random_int(1, 5),
            'connectivity_type' => '2G/3G',
            'avg_completion_rate' => round(random_int(40, 90) / 100, 2),
            'last_sync' => now()->subHours(random_int(1, 48))->toIso8601String(),
        ]);
    }

    public function performanceReport()
    {
        return $this->success([
            'overall' => [
                'avg_score' => 72.5,
                'avg_completion_rate' => 0.68,
                'avg_time_per_lesson' => 25,
            ],
            'by_subject' => [
                ['subject' => 'Matemáticas', 'avg_score' => 68.2, 'completion' => 0.72],
                ['subject' => 'Lenguaje', 'avg_score' => 75.1, 'completion' => 0.65],
                ['subject' => 'Ciencias', 'avg_score' => 70.8, 'completion' => 0.70],
                ['subject' => 'Sociales', 'avg_score' => 73.4, 'completion' => 0.63],
            ],
            'by_connectivity' => [
                ['type' => '2G', 'avg_score' => 65.2, 'completion' => 0.55],
                ['type' => '3G', 'avg_score' => 71.8, 'completion' => 0.68],
                ['type' => '4G', 'avg_score' => 76.4, 'completion' => 0.78],
            ],
        ]);
    }

    public function connectivityReport()
    {
        return $this->success([
            'nodes_online' => random_int(5, 45),
            'nodes_offline' => random_int(1, 10),
            'avg_latency_ms' => random_int(100, 800),
            'peak_sync_hours' => ['06:00', '12:00', '18:00'],
            'offline_capable_users' => random_int(500, 3000),
        ]);
    }

    public function adoptionReport()
    {
        return $this->success([
            'total_users' => random_int(1000, 5000),
            'active_users_30d' => random_int(500, 3000),
            'new_users_this_month' => random_int(50, 300),
            'offline_usage_percent' => round(random_int(30, 70)),
            'feature_adoption' => [
                'offline_content' => '85%',
                'learning_paths' => '62%',
                'sync_automatico' => '45%',
                'recomendaciones_ia' => '38%',
            ],
        ]);
    }

    public function export(string $type)
    {
        $format = request('format', 'json');
        $data = match ($type) {
            'students' => ['file' => 'reporte_estudiantes.csv', 'rows' => 1500],
            'performance' => ['file' => 'reporte_rendimiento.csv', 'rows' => 800],
            'connectivity' => ['file' => 'reporte_conectividad.csv', 'rows' => 50],
            default => ['file' => "reporte_{$type}.csv", 'rows' => 100],
        };

        return $this->success($data);
    }
}
