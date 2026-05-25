<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Content extends Model
{
    use SoftDeletes;

    protected $table = 'contents';

    protected $fillable = [
        'uuid', 'title', 'description', 'content_type', 'category_id',
        'difficulty_level', 'estimated_duration_minutes', 'file_url', 'file_size_bytes',
        'file_hash', 'storage_path', 'thumbnail_url', 'version',
        'is_offline_available', 'is_published', 'metadata', 'published_at', 'created_by',
    ];

    protected $casts = [
        'metadata' => 'array',
        'is_offline_available' => 'boolean',
        'is_published' => 'boolean',
        'published_at' => 'datetime',
        'file_size_bytes' => 'integer',
    ];

    public function category()
    {
        return $this->belongsTo(ContentCategory::class, 'category_id');
    }

    public function dependencies()
    {
        return $this->hasMany(ContentDependency::class, 'content_id');
    }

    public function distributions()
    {
        return $this->hasMany(ContentDistribution::class, 'content_id');
    }

    public function scopeOfflineAvailable($query)
    {
        return $query->where('is_offline_available', true);
    }

    public function scopePublished($query)
    {
        return $query->where('is_published', true);
    }

    public function scopeByType($query, string $type)
    {
        return $query->where('content_type', $type);
    }

    public function incrementVersion(): int
    {
        $this->increment('version');
        return $this->version;
    }
}
