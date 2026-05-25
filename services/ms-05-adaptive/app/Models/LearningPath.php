<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LearningPath extends Model
{
    protected $table = 'learning_paths';

    protected $fillable = [
        'uuid', 'user_id', 'name', 'subject_area', 'status',
        'progress_percent', 'started_at', 'completed_at',
        'last_activity_at', 'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
        'progress_percent' => 'decimal:2',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'last_activity_at' => 'datetime',
    ];

    public function items()
    {
        return $this->hasMany(LearningPathItem::class, 'learning_path_id');
    }

    public function user()
    {
        return $this->belongsTo(\App\Models\User::class);
    }
}
