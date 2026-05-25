<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable implements JWTSubject
{
    use SoftDeletes, HasFactory;

    protected $fillable = [
        'uuid', 'full_name', 'email', 'password', 'role_id',
        'document_id', 'phone', 'avatar_url', 'locale',
        'is_active', 'last_login_at', 'last_sync_at',
    ];

    protected $hidden = ['password'];

    protected $casts = [
        'is_active' => 'boolean',
        'last_login_at' => 'datetime',
        'last_sync_at' => 'datetime',
    ];

    public function getJWTIdentifier(): mixed
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims(): array
    {
        return [
            'user_uuid' => $this->uuid,
            'role' => $this->role?->slug,
            'is_offline_capable' => true,
        ];
    }

    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    public function profile()
    {
        return $this->hasOne(UserProfile::class);
    }

    public function sessions()
    {
        return $this->hasMany(UserSession::class);
    }

    public function offlineTokens()
    {
        return $this->hasMany(OfflineToken::class);
    }

    public function hasRole(string $slug): bool
    {
        return $this->role?->slug === $slug;
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
