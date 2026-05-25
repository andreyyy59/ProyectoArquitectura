<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class NotificationController extends Controller
{
    public function send(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|integer',
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'type' => 'required|in:INFO,WARNING,SUCCESS,SYNC,ALERT',
            'priority' => 'sometimes|in:LOW,MEDIUM,HIGH,CRITICAL',
            'data' => 'nullable|array',
        ]);

        $notification = [
            'id' => (string) Str::uuid(),
            'user_id' => $validated['user_id'],
            'title' => $validated['title'],
            'body' => $validated['body'],
            'type' => $validated['type'],
            'priority' => $validated['priority'] ?? 'MEDIUM',
            'data' => $validated['data'] ?? [],
            'is_read' => false,
            'created_at' => now()->toIso8601String(),
        ];

        $key = "notifications:user:{$validated['user_id']}";
        $notifications = Cache::get($key, []);
        array_unshift($notifications, $notification);
        $notifications = array_slice($notifications, 0, 100);
        Cache::put($key, $notifications, now()->addDays(30));

        return $this->success($notification, 201);
    }

    public function list(int $userId)
    {
        $key = "notifications:user:{$userId}";
        $notifications = Cache::get($key, []);

        $unread = count(array_filter($notifications, fn($n) => !$n['is_read']));

        return $this->success([
            'notifications' => $notifications,
            'total' => count($notifications),
            'unread' => $unread,
        ]);
    }

    public function markAsRead(string $id)
    {
        $key = "notifications:user:*";
        $keys = Cache::get($key, []);

        foreach (Cache::getMultiple(Cache::get('notification_keys', [])) as $userId => $notifications) {
            foreach ($notifications as &$n) {
                if ($n['id'] === $id) {
                    $n['is_read'] = true;
                    $n['read_at'] = now()->toIso8601String();
                    Cache::put("notifications:user:{$userId}", $notifications, now()->addDays(30));
                    return $this->success(['message' => 'Notificación marcada como leída']);
                }
            }
        }

        return $this->error('Notificación no encontrada', 404);
    }

    public function registerPushToken(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|integer',
            'push_token' => 'required|string',
            'platform' => 'required|in:WEB,ANDROID,IOS',
        ]);

        $key = "push:tokens:{$validated['user_id']}";
        Cache::put($key, [
            'token' => $validated['push_token'],
            'platform' => $validated['platform'],
            'registered_at' => now()->toIso8601String(),
        ], now()->addDays(90));

        return $this->success(['message' => 'Token registrado']);
    }

    public function sendBatch(Request $request)
    {
        $validated = $request->validate([
            'user_ids' => 'required|array',
            'user_ids.*' => 'integer',
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'type' => 'required|in:INFO,WARNING,SUCCESS,SYNC,ALERT',
        ]);

        $sent = 0;
        foreach ($validated['user_ids'] as $userId) {
            $notification = [
                'id' => (string) Str::uuid(),
                'user_id' => $userId,
                'title' => $validated['title'],
                'body' => $validated['body'],
                'type' => $validated['type'],
                'is_read' => false,
                'created_at' => now()->toIso8601String(),
            ];

            $key = "notifications:user:{$userId}";
            $notifications = Cache::get($key, []);
            array_unshift($notifications, $notification);
            $notifications = array_slice($notifications, 0, 100);
            Cache::put($key, $notifications, now()->addDays(30));
            $sent++;
        }

        return $this->success([
            'sent' => $sent,
            'total_target' => count($validated['user_ids']),
        ]);
    }
}
