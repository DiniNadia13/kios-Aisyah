<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductDeleteTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_delete_product_even_if_it_has_order_history(): void
    {
        $admin = User::create([
            'name' => 'Admin Test',
            'email' => 'admin@test.com',
            'phone' => '08123456789',
            'password' => bcrypt('secret'),
            'role' => 'admin',
        ]);

        $category = Category::create(['name' => 'Beras']);
        $product = Product::create([
            'category_id' => $category->id,
            'name' => 'Beras Uji Coba Hapus',
            'price' => 50000,
            'unit' => 'kg',
            'stock' => 10,
        ]);

        // Simulasikan ada order masa lalu yang membeli produk ini
        $order = Order::create([
            'code' => 'TEST-ORD-'.uniqid(),
            'user_id' => $admin->id,
            'delivery_method' => 'pickup',
            'subtotal' => 50000,
            'total' => 50000,
            'payment_method' => 'cod',
            'payment_status' => 'paid',
            'status' => 'completed',
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'name' => $product->name,
            'price' => $product->price,
            'quantity' => 1,
            'subtotal' => 50000,
        ]);

        // Admin menghapus produk
        $response = $this->actingAs($admin)->deleteJson('/api/admin/products/'.$product->id);

        $response->assertStatus(200);
        $this->assertSoftDeleted('products', ['id' => $product->id]);

        // Pastikan tidak muncul lagi di katalog publik maupun daftar admin
        $this->assertFalse(Product::where('id', $product->id)->exists());
        // Namun riwayat order tetap utuh
        $this->assertDatabaseHas('order_items', [
            'order_id' => $order->id,
            'name' => 'Beras Uji Coba Hapus',
        ]);
    }
}
