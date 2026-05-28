<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Content extends Model
{
    protected $table = 'contents';

    protected $fillable = [
        'uuid', 'title', 'description', 'content_type',
        'subject_area', 'difficulty_level',
        'estimated_duration_minutes', 'is_offline_available',
    ];
}
