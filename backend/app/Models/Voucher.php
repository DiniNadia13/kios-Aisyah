<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    protected $guarded = [];

    protected $casts = [
        'is_active' => 'boolean',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];

    public function scopeLive($q)
    {
        return $q->where('is_active', true)
            ->where(fn ($w) => $w->whereNull('starts_at')->orWhere('starts_at', '<=', now()))
            ->where(fn ($w) => $w->whereNull('ends_at')->orWhere('ends_at', '>=', now()))
            ->where(fn ($w) => $w->whereNull('quota')->orWhereColumn('used_count', '<', 'quota'));
    }

    /** Hitung potongan untuk subtotal tertentu (0 jika tidak memenuhi syarat). */
    public function discountFor(int $subtotal): int
    {
        if ($subtotal < $this->min_purchase) {
            return 0;
        }
        $d = $this->type === 'percent'
            ? intdiv($subtotal * $this->value, 100)
            : $this->value;
        if ($this->max_discount) {
            $d = min($d, $this->max_discount);
        }

        return min($d, $subtotal);
    }
}

