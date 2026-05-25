<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $users = User::with('role', 'profile')
            ->when($request->role, fn($q, $r) => $q->whereHas('role', fn($q) => $q->where('slug', $r)))
            ->when($request->search, fn($q, $s) => $q->where('full_name', 'like', "%{$s}%")
                ->orWhere('email', 'like', "%{$s}%"))
            ->when($request->active !== null, fn($q) => $q->where('is_active', $request->boolean('active')))
            ->paginate($request->per_page ?? 20);

        return $this->success($users);
    }

    public function show($uuid)
    {
        $user = User::with('role', 'profile')->where('uuid', $uuid)->firstOrFail();
        return $this->success($user);
    }

    public function update(Request $request, $uuid)
    {
        $user = User::where('uuid', $uuid)->firstOrFail();

        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'avatar_url' => 'sometimes|url|max:500',
            'locale' => 'sometimes|string|size:2',
            'is_active' => 'sometimes|boolean',
        ]);

        $user->update($validated);

        return $this->success($user->load('role'));
    }

    public function syncStatus(Request $request)
    {
        $validated = $request->validate([
            'user_ids' => 'required|array',
            'user_ids.*' => 'exists:users,uuid',
        ]);

        $users = User::whereIn('uuid', $validated['user_ids'])
            ->select('uuid', 'last_sync_at', 'updated_at')
            ->get()
            ->keyBy('uuid');

        return $this->success($users);
    }

    public function markSynced(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|exists:users,uuid',
            'synced_at' => 'required|date',
        ]);

        User::where('uuid', $validated['user_id'])
            ->update(['last_sync_at' => $validated['synced_at']]);

        return $this->success(['message' => 'Sincronización marcada']);
    }
}
