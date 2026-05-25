<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LearningPathItem extends Model
{
    protected $table = 'learning_path_items';

    protected $fillable = [
        'learning_path_id', 'content_id', 'sort_order', 'status',
        'score', 'time_spent_seconds', 'attempts_count', 'max_attempts',
        'is_mandatory', 'completed_at',
    ];

    protected $casts = [
        'score' => 'decimal:2',
        'completed_at' => 'datetime',
        'is_mandatory' => 'boolean',
    ];

    public function learningPath()
    {
        return $this->belongsTo(LearningPath::class, 'learning_path_id');
    }

    public function content()
    {
        return $this->belongsTo(\App\Models\Content::class, 'content_id');
    }
}
