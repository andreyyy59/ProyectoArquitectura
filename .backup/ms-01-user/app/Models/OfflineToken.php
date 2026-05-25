<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OfflineToken extends Model
{
    protected $fillable = [
        'user_id', 'token_hash', 'issued_at', 'expires_at',
        'last_validated_at', 'is_revoked',
    ];

    protected $casts = [
        'issued_at' => 'datetime',
        'expires_at' => 'datetime',
        'last_validated_at' => 'datetime',
        'is_revoked' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function scopeValid($query)
    {
        return $query->where('is_revoked', false)
            ->where('expires_at', '>', now());
    }
}
