<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use SoftDeletes;

    protected $guarded = [];

    protected $casts = [
        'is_active' => 'boolean',
        'is_flash_sale' => 'boolean',
        'promo_starts_at' => 'datetime',
        'promo_ends_at' => 'datetime',
    ];

    protected $appends = ['final_price', 'has_promo', 'image_url'];

    public function getImageUrlAttribute(): ?string
    {
        if (! $this->image) {
            return null;
        }
        if (str_starts_with($this->image, 'http://') || str_starts_with($this->image, 'https://')) {
            return $this->image;
        }
        return asset('storage/'.$this->image);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    /** Promo aktif jika harga promo diisi admin dan dalam jadwal. */
    public function getHasPromoAttribute(): bool
    {
        if (! $this->promo_price || $this->promo_price >= $this->price) {
            return false;
        }
        $now = now();
        if ($this->promo_starts_at && $now->lt($this->promo_starts_at)) {
            return false;
        }
        if ($this->promo_ends_at && $now->gt($this->promo_ends_at)) {
            return false;
        }

        return true;
    }

    public function getFinalPriceAttribute(): int
    {
        return $this->has_promo ? $this->promo_price : $this->price;
    }

    public function scopeActive($q)
    {
        return $q->where('is_active', true);
    }
}

