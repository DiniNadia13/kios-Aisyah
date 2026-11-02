<?php

namespace App\Services;

use App\Models\Product;
use App\Models\Setting;
use App\Models\ShippingZone;
use App\Models\Voucher;
use Illuminate\Validation\ValidationException;

class CheckoutService
{
    public const DEFAULT_FREE_SHIPPING_MIN = 150000;

    public static function freeShippingMin(): int
    {
        return (int) Setting::get('free_shipping_min', self::DEFAULT_FREE_SHIPPING_MIN);
    }

    /**
     * Hitung ringkasan harga.
     *
     * @param  array<int,array{product_id:int,quantity:int}>  $items
     */
    public function quote(array $items, ?string $voucherCode, string $deliveryMethod, ?int $zoneId): array
    {
        $lines = [];
        $subtotal = 0;

        foreach ($items as $item) {
            $product = Product::active()->find($item['product_id']);
            if (! $product) {
                throw ValidationException::withMessages(['items' => 'Produk tidak ditemukan atau tidak aktif.']);
            }
            $qty = (int) $item['quantity'];
            if ($qty > $product->stock) {
                throw ValidationException::withMessages(['items' => "Stok {$product->name} tidak mencukupi (sisa {$product->stock})."]);
            }
            $lineTotal = $product->final_price * $qty;
            $subtotal += $lineTotal;
            $lines[] = [
                'product' => $product,
                'quantity' => $qty,
                'price' => $product->final_price,
                'subtotal' => $lineTotal,
            ];
        }

        // Voucher (dibuat admin)
        $discount = 0;
        $voucher = null;
        if ($voucherCode) {
            $voucher = Voucher::live()->where('code', strtoupper($voucherCode))->first();
            if (! $voucher) {
                throw ValidationException::withMessages(['voucher_code' => 'Kode promo tidak valid atau sudah berakhir.']);
            }
            $discount = $voucher->discountFor($subtotal);
            if ($discount === 0) {
                throw ValidationException::withMessages(['voucher_code' => 'Minimal belanja untuk promo ini Rp'.number_format($voucher->min_purchase, 0, ',', '.').'.']);
            }
        }

        $afterDiscount = $subtotal - $discount;
        $min = self::freeShippingMin();

        // Ongkir: ambil di toko / belanja >= batas = gratis
        if ($deliveryMethod === 'pickup' || $afterDiscount >= $min) {
            $shipping = 0;
        } else {
            $zone = $zoneId ? ShippingZone::where('is_active', true)->find($zoneId) : null;
            $shipping = $zone ? $zone->fee : (int) Setting::get('default_shipping_fee', 0);
        }

        return [
            'lines' => $lines,
            'voucher' => $voucher,
            'subtotal' => $subtotal,
            'discount' => $discount,
            'shipping_fee' => $shipping,
            'total' => $afterDiscount + $shipping,
            'free_shipping_min' => $min,
            'free_shipping' => $deliveryMethod === 'pickup' || $afterDiscount >= $min,
            'remaining_for_free_shipping' => max(0, $min - $afterDiscount),
        ];
    }
}

