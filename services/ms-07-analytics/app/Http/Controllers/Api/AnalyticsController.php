<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use EduConnect\Protocols\XapiStatement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class AnalyticsController extends Controller
{
    private array $xapiStore = [];

    public function storeStatement(Request $request)
    {
        $validated = $request->validate([
            'actor' => 'required|array',
            'verb' => 'required|array',
            'object' => 'required|array',
            'result' => 'nullable|array',
            'context' => 'nullable|array',
            'timestamp' => 'nullable|date',
        ]);

        $statement = XapiStatement::make()
            ->withId((string) Str::uuid())
            ->withTimestamp($validated['timestamp'] ?? now()->toIso8601String());

        $statementData = $statement->toArray();
        $statementData['actor'] = $validated['actor'];
        $statementData['verb'] = $validated['verb'];
        $statementData['object'] = $validated['object'];
        $statementData['result'] = $validated['result'] ?? [];
        $statementData['context'] = $validated['context'] ?? [];

        $this->storeXapiStatement($statementData);

        return $this->success([
            'id' => $statementData['id'],
            'stored' => $statementData['timestamp'],
            'version' => '1.0.3',
        ], 201);
    }

    public function storeStatements(Request $request)
    {
        $validated = $request->validate([
            'statements' => 'required|array',
            'statements.*' => 'required|array',
        ]);

        $ids = [];
        foreach ($validated['statements'] as $stmt) {
            $id = (string) Str::uuid();
            $stmt['id'] = $id;
            $stmt['stored'] = now()->toIso8601String();
            $this->storeXapiStatement($stmt);
            $ids[] = $id;
        }

        return $this->success([
            'ids' => $ids,
            'count' => count($ids),
        ], 201);
    }

    public function getStatements(Request $request)
    {
        $statements = Cache::get('xapi:statements', []);
        $statements = array_reverse($statements);

        if ($request->agent) {
            $statements = array_filter($statements, fn($s) =>
                ($s['actor']['mbox'] ?? '') === $request->agent
            );
        }

        return $this->success([
            'statements' => array_values(array_slice($statements, 0, 100)),
            'more' => count($statements) > 100 ? '?offset=100' : null,
        ]);
    }

    public function userProgress(int $userId)
    {
        $statements = Cache::get('xapi:statements', []);
        $userStatements = array_filter($statements, fn($s) =>
            ($s['actor']['account']['name'] ?? '') === (string) $userId
        );

        $progress = [
            'total_activities' => count($userStatements),
            'completed' => count(array_filter($userStatements, fn($s) =>
                $s['verb']['id'] === XapiStatement::VERBS['COMPLETED']
            )),
            'avg_score' => $this->averageScore($userStatements),
            'total_time_seconds' => $this->totalTime($userStatements),
        ];

        return $this->success($progress);
    }

    public function contentProgress(int $userId, int $contentId)
    {
        $statements = Cache::get('xapi:statements', []);

        $filtered = array_filter($statements, fn($s) =>
            ($s['actor']['account']['name'] ?? '') === (string) $userId
            && str_contains($s['object']['id'] ?? '', "/contents/{$contentId}")
        );

        return $this->success([
            'user_id' => $userId,
            'content_id' => $contentId,
            'interactions' => count($filtered),
            'last_event' => !empty($filtered) ? end($filtered) : null,
        ]);
    }

    public function userSummary(int $userId)
    {
        $progress = $this->userProgress($userId);
        $progress['user_id'] = $userId;
        $progress['generated_at'] = now()->toIso8601String();
        return $this->success($progress);
    }

    public function aggregatedMetrics(Request $request)
    {
        $statements = Cache::get('xapi:statements', []);
        $total = count($statements);

        $verbs = array_count_values(array_map(fn($s) => $s['verb']['id'] ?? 'unknown', $statements));

        return $this->success([
            'total_statements' => $total,
            'unique_users' => count(array_unique(array_map(
                fn($s) => $s['actor']['account']['name'] ?? 'unknown', $statements
            ))),
            'verbs_distribution' => $verbs,
            'period' => [
                'from' => $statements[0]['timestamp'] ?? null,
                'to' => $statements[count($statements) - 1]['timestamp'] ?? null,
            ],
        ]);
    }

    public function syncXapiStatements(Request $request)
    {
        $validated = $request->validate([
            'statements' => 'required|array',
        ]);

        $synced = 0;
        foreach ($validated['statements'] as $stmt) {
            $stmt['id'] = $stmt['id'] ?? (string) Str::uuid();
            $stmt['stored'] = now()->toIso8601String();
            $this->storeXapiStatement($stmt);
            $synced++;
        }

        return $this->success([
            'synced' => $synced,
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    private function storeXapiStatement(array $statement): void
    {
        $key = 'xapi:statements';
        $statements = Cache::get($key, []);
        $statements[] = $statement;
        Cache::put($key, $statements, now()->addDays(30));
    }

    private function averageScore(array $statements): float
    {
        $scores = array_filter(array_map(fn($s) =>
            $s['result']['score']['raw'] ?? null, $statements
        ));
        return empty($scores) ? 0 : round(array_sum($scores) / count($scores), 2);
    }

    private function totalTime(array $statements): int
    {
        return array_sum(array_map(fn($s) => $this->parseDuration($s['result']['duration'] ?? ''), $statements));
    }

    private function parseDuration(string $duration): int
    {
        if (preg_match('/PT(\d+)S/', $duration, $m)) return (int) $m[1];
        return 0;
    }
}
