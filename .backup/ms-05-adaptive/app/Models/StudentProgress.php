<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentProgress extends Model
{
    protected $table = 'student_progress';

    protected $fillable = [
        'user_id', 'content_id', 'progress_percent', 'score',
        'time_spent_seconds', 'interaction_count', 'last_position',
        'status', 'is_offline', 'client_timestamp', 'synced_at',
    ];

    protected $casts = [
        'progress_percent' => 'decimal:2',
        'score' => 'decimal:2',
        'is_offline' => 'boolean',
        'client_timestamp' => 'datetime',
        'synced_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
