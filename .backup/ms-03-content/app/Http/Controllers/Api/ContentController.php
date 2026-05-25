<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Content;
use App\Models\ContentDistribution;
use App\Models\ContentCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ContentController extends Controller
{
    public function index(Request $request)
    {
        $contents = Content::with('category')
            ->when($request->type, fn($q, $t) => $q->where('content_type', $t))
            ->when($request->difficulty, fn($q, $d) => $q->where('difficulty_level', $d))
            ->when($request->category, fn($q, $c) => $q->where('category_id', $c))
            ->when($request->published !== null, fn($q) => $q->where('is_published', $request->boolean('published')))
            ->when($request->offline !== null, fn($q) => $q->where('is_offline_available', $request->boolean('offline')))
            ->when($request->search, fn($q, $s) => $q->where('title', 'like', "%{$s}%")
                ->orWhere('description', 'like', "%{$s}%"))
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 20);

        return $this->success($contents);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:500',
            'description' => 'nullable|string',
            'content_type' => 'required|in:VIDEO,PDF,EXERCISE,QUIZ,INTERACTIVE,AUDIO,DOCUMENT',
            'category_id' => 'nullable|exists:content_categories,id',
            'difficulty_level' => 'sometimes|in:BEGINNER,INTERMEDIATE,ADVANCED',
            'estimated_duration_minutes' => 'nullable|integer|min:0',
            'file_url' => 'nullable|string|max:1000',
            'file_size_bytes' => 'nullable|integer|min:0',
            'file_hash' => 'nullable|string|max:64',
            'metadata' => 'nullable|array',
        ]);

        $validated['uuid'] = (string) Str::uuid();
        $validated['version'] = 1;

        $content = Content::create($validated);

        return $this->success($content->load('category'), 201);
    }

    public function show($uuid)
    {
        $content = Content::with('category', 'dependencies.dependsOn', 'distributions')
            ->where('uuid', $uuid)
            ->firstOrFail();

        return $this->success($content);
    }

    public function update(Request $request, $uuid)
    {
        $content = Content::where('uuid', $uuid)->firstOrFail();

        $validated = $request->validate([
            'title' => 'sometimes|string|max:500',
            'description' => 'sometimes|string',
            'difficulty_level' => 'sometimes|in:BEGINNER,INTERMEDIATE,ADVANCED',
            'estimated_duration_minutes' => 'sometimes|integer|min:0',
            'file_url' => 'sometimes|string|max:1000',
            'file_hash' => 'sometimes|string|max:64',
            'metadata' => 'sometimes|array',
            'is_offline_available' => 'sometimes|boolean',
        ]);

        $validated['version'] = $content->version + 1;
        $content->update($validated);

        return $this->success($content->fresh()->load('category'));
    }

    public function destroy($uuid)
    {
        $content = Content::where('uuid', $uuid)->firstOrFail();
        $content->delete();

        return $this->success(['message' => 'Contenido eliminado']);
    }

    public function publish($uuid)
    {
        $content = Content::where('uuid', $uuid)->firstOrFail();

        $content->update([
            'is_published' => true,
            'published_at' => now(),
        ]);

        return $this->success($content->fresh());
    }

    public function distribute(Request $request, $uuid)
    {
        $content = Content::where('uuid', $uuid)->firstOrFail();

        $validated = $request->validate([
            'edge_node_ids' => 'required|array',
            'edge_node_ids.*' => 'integer|exists:edge_nodes,id',
        ]);

        $distributions = [];
        foreach ($validated['edge_node_ids'] as $nodeId) {
            $distributions[] = ContentDistribution::create([
                'content_id' => $content->id,
                'edge_node_id' => $nodeId,
                'distribution_status' => 'PENDING',
                'version_at_distribution' => $content->version,
            ]);
        }

        return $this->success($distributions, 201);
    }

    public function categories()
    {
        $categories = ContentCategory::withCount('contents')
            ->whereNull('parent_id')
            ->with('children')
            ->get();

        return $this->success($categories);
    }
}
