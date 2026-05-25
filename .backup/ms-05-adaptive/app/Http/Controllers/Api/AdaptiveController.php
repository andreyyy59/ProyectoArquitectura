<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LearningPath;
use App\Models\StudentProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class AdaptiveController extends Controller
{
    public function generatePath(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|integer',
            'subject_area' => 'nullable|string',
            'content_ids' => 'nullable|array',
        ]);

        $path = LearningPath::create([
            'uuid' => (string) Str::uuid(),
            'user_id' => $validated['user_id'],
            'subject_area' => $validated['subject_area'] ?? 'general',
            'status' => 'ACTIVE',
        ]);

        if (!empty($validated['content_ids'])) {
            foreach ($validated['content_ids'] as $order => $contentId) {
                $path->items()->create([
                    'content_id' => $contentId,
                    'sort_order' => $order,
                    'status' => 'PENDING',
                ]);
            }
        }

        // Consulta al motor de IA para recomendaciones
        try {
            $aiResponse = Http::timeout(5)->post(config('services.ai.url') . '/recommend', [
                'user_id' => $validated['user_id'],
                'subject' => $validated['subject_area'] ?? 'general',
            ]);

            if ($aiResponse->successful()) {
                $path->update(['metadata' => $aiResponse->json()]);
            }
        } catch (\Throwable $e) {
            // Opera offline sin recomendaciones IA
        }

        return $this->success($path->load('items'), 201);
    }

    public function getPath($uuid)
    {
        $path = LearningPath::with('items.content')
            ->where('uuid', $uuid)
            ->firstOrFail();

        return $this->success($path);
    }

    public function nextActivity($uuid)
    {
        $path = LearningPath::where('uuid', $uuid)->firstOrFail();

        $nextItem = $path->items()
            ->whereIn('status', ['PENDING', 'AVAILABLE'])
            ->orderBy('sort_order')
            ->first();

        if (!$nextItem) {
            return $this->success(['message' => 'Ruta completada', 'completed' => true]);
        }

        $nextItem->update(['status' => 'IN_PROGRESS']);

        return $this->success([
            'next_activity' => $nextItem->load('content'),
            'progress' => $path->progress_percent,
        ]);
    }

    public function evaluate(Request $request, $uuid)
    {
        $validated = $request->validate([
            'content_id' => 'required|integer',
            'score' => 'required|numeric|between:0,100',
            'time_spent_seconds' => 'required|integer',
            'completed' => 'required|boolean',
        ]);

        $path = LearningPath::where('uuid', $uuid)->firstOrFail();

        $item = $path->items()
            ->where('content_id', $validated['content_id'])
            ->firstOrFail();

        $item->update([
            'status' => $validated['completed'] ? 'COMPLETED' : 'FAILED',
            'score' => $validated['score'],
            'time_spent_seconds' => $validated['time_spent_seconds'],
            'completed_at' => $validated['completed'] ? now() : null,
        ]);

        $totalItems = $path->items()->count();
        $completedItems = $path->items()->where('status', 'COMPLETED')->count();
        $progress = $totalItems > 0 ? ($completedItems / $totalItems) * 100 : 0;

        $path->update([
            'progress_percent' => $progress,
            'last_activity_at' => now(),
            'status' => $progress >= 100 ? 'COMPLETED' : 'ACTIVE',
            'completed_at' => $progress >= 100 ? now() : null,
        ]);

        return $this->success([
            'progress_percent' => $progress,
            'path_status' => $path->status,
            'next_activity' => $path->items()
                ->whereIn('status', ['PENDING', 'AVAILABLE'])
                ->orderBy('sort_order')
                ->first()?->load('content'),
        ]);
    }

    public function recordProgress(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|integer',
            'content_id' => 'required|integer',
            'progress_percent' => 'required|numeric|between:0,100',
            'score' => 'nullable|numeric|between:0,100',
            'time_spent_seconds' => 'nullable|integer',
            'interaction_count' => 'nullable|integer',
            'last_position' => 'nullable|string',
            'status' => 'required|in:NOT_STARTED,IN_PROGRESS,COMPLETED,FAILED',
            'is_offline' => 'boolean',
            'client_timestamp' => 'nullable|date',
        ]);

        $progress = StudentProgress::updateOrCreate(
            ['user_id' => $validated['user_id'], 'content_id' => $validated['content_id']],
            $validated + ['synced_at' => now()]
        );

        return $this->success($progress);
    }

    public function recommendations($userId)
    {
        try {
            $response = Http::timeout(5)->get(config('services.ai.url') . "/recommend/{$userId}");
            return $this->success($response->json());
        } catch (\Throwable $e) {
            // Recomendaciones offline por defecto
            return $this->success([
                'user_id' => $userId,
                'recommendations' => [],
                'source' => 'offline_default',
            ]);
        }
    }
}
