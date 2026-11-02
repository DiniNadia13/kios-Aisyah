<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\ShippingZone;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ShippingTest extends TestCase
{
    use RefreshDatabase;

    private function product(int $price): Product
    {
        $c = Category::create(['name' => 'Test']);

        return Product::create(['category_id' => $c->id, 'name' => 'P'.$price, 'price' => $price, 'stock' => 100]);
    }

    private function quote(Product $p, int $qty, array $extra = [])
    {
        return $this->postJson('/api/cart/quote', [
            'items' => [['product_id' => $p->id, 'quantity' => $qty]],
            'delivery_method' => 'delivery',
        ] + $extra);
    }

    public function test_below_threshold_pays_zone_fee(): void
    {
        $zone = ShippingZone::create(['name' => 'Dekat', 'fee' => 8000]);
        $this->quote($this->product(50000), 2, ['shipping_zone_id' => $zone->id]) // 100.000
            ->assertOk()->assertJson(['shipping_fee' => 8000, 'free_shipping' => false, 'remaining_for_free_shipping' => 50000, 'total' => 108000]);
    }

    public function test_at_or_above_150k_is_free(): void
    {
        $zone = ShippingZone::create(['name' => 'Dekat', 'fee' => 8000]);
        $this->quote($this->product(50000), 3, ['shipping_zone_id' => $zone->id]) // 150.000
            ->assertOk()->assertJson(['shipping_fee' => 0, 'free_shipping' => true, 'total' => 150000]);
    }

    public function test_promo_price_is_used(): void
    {
        $p = $this->product(60000);
        $p->update(['promo_price' => 50000]);
        $this->quote($p, 3)->assertOk()->assertJson(['subtotal' => 150000, 'free_shipping' => true]);
    }
}

