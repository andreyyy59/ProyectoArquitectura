<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    public const STUDENT = 'student';
    public const TEACHER = 'teacher';
    public const ADMIN = 'admin';
    public const EDGE_ADMIN = 'edge_admin';

    protected $fillable = ['name', 'slug', 'description'];

    public function users()
    {
        return $this->hasMany(User::class);
    }
}
