<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use App\Models\Banner;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\Setting;
use App\Models\ShippingZone;
use App\Models\User;
use App\Models\Voucher;
use App\Services\CheckoutService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class ShopController extends Controller
{
    // ---------- Auth ----------
    public function register(Request $r)
    {
        $data = $r->validate([
            'name' => 'required|string|max:100',
            'phone' => 'required|string|max:20|unique:users,phone',
            'password' => 'required|string|min:6',
        ]);
        $user = User::create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'email' => $data['phone'].'@kiosaisyha.local',
            'password' => $data['password'],
        ]);

        return ['token' => $user->createToken('mobile')->plainTextToken, 'user' => $user];
    }

    public function login(Request $r)
    {
        $data = $r->validate(['phone' => 'required', 'password' => 'required']);
        $user = User::where('phone', $data['phone'])->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['phone' => 'No. HP atau password salah.']);
        }

        return ['token' => $user->createToken('mobile')->plainTextToken, 'user' => $user];
    }

    public function me(Request $r)
    {
        return $r->user();
    }

    public function logout(Request $r)
    {
        $r->user()->currentAccessToken()->delete();

        return ['message' => 'ok'];
    }

    // ---------- Katalog & promo (data promo diisi admin) ----------
    public function home()
    {
        $products = Product::active()->with('category');

        return [
            'banners' => Banner::live()->where('placement', 'home_top')->orderBy('sort_order')->get(),
            'popup' => Banner::live()->where('placement', 'popup')->orderBy('sort_order')->first(),
            'flash_sale' => (clone $products)->where('is_flash_sale', true)
                ->whereNotNull('promo_price')->get()->filter->has_promo->values(),
            'categories' => Category::where('is_active', true)->orderBy('sort_order')->get(),
            'best_sellers' => (clone $products)->orderByDesc('sold_count')->limit(10)->get(),
            'newest' => (clone $products)->latest()->limit(10)->get(),
            'vouchers' => Voucher::live()->limit(5)->get(),
            'free_shipping_min' => CheckoutService::freeShippingMin(),
            'store_whatsapp' => Setting::get('store_whatsapp', '6282154306904'),
            'payment_info' => [
                'bank_name' => Setting::get('store_bank_name', 'BCA / BRI / Mandiri'),
                'bank_account' => Setting::get('store_bank_account', ''),
                'bank_holder' => Setting::get('store_bank_holder', 'Kios Aisyha'),
                'qris_image' => Setting::get('store_qris_image') ? asset('storage/'.Setting::get('store_qris_image')) : null,
                'qris_name' => Setting::get('store_qris_name', 'Kios Aisyha'),
                'store_name' => Setting::get('store_name', 'Kios Aisyha'),
                'store_address' => Setting::get('store_address', 'Jl. Kios Aisyha, Pusat Sembako Segar'),
                'store_phone' => Setting::get('store_phone', '0821-5430-6904'),
                'store_hours' => Setting::get('store_hours', '07:00 - 21:00 WIB'),
            ],
        ];
    }

    public function categories()
    {
        return Category::where('is_active', true)->orderBy('sort_order')->get();
    }

    public function products(Request $r)
    {
        $q = Product::active()->with('category');
        if ($r->filled('category_id')) {
            $q->where('category_id', $r->category_id);
        }
        if ($r->filled('q')) {
            $q->where('name', 'like', '%'.$r->q.'%');
        }
        match ($r->sort) {
            'price_asc' => $q->orderBy('price'),
            'price_desc' => $q->orderByDesc('price'),
            'best' => $q->orderByDesc('sold_count'),
            default => $q->latest(),
        };

        return $q->paginate(20);
    }

    public function product(Product $product)
    {
        return $product->load('category');
    }

    public function vouchers()
    {
        return Voucher::live()->get(['code', 'description', 'type', 'value', 'max_discount', 'min_purchase', 'ends_at']);
    }

    public function shippingZones()
    {
        return ShippingZone::where('is_active', true)->get();
    }

    public function cartUpsell(Request $r)
    {
        $maxPrice = (int) $r->input('max_price', 25000);

        return Product::active()
            ->with('category')
            ->where('price', '<=', $maxPrice)
            ->where('stock', '>', 0)
            ->orderBy('price')
            ->limit(10)
            ->get();
    }

    // ---------- Alamat ----------
    public function addresses(Request $r)
    {
        return $r->user()->addresses()->with('zone')->get();
    }

    public function storeAddress(Request $r)
    {
        $data = $r->validate([
            'label' => 'nullable|string|max:30',
            'recipient' => 'required|string',
            'phone' => 'required|string',
            'full_address' => 'required|string',
            'shipping_zone_id' => 'nullable|exists:shipping_zones,id',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'is_default' => 'boolean',
        ]);
        if (! empty($data['is_default'])) {
            $r->user()->addresses()->update(['is_default' => false]);
        }

        return $r->user()->addresses()->create($data);
    }

    public function destroyAddress(Request $r, Address $address)
    {
        abort_unless($address->user_id === $r->user()->id, 403);
        $address->delete();

        return ['message' => 'ok'];
    }

    // ---------- Keranjang / checkout ----------
    private function quoteRules(): array
    {
        return [
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer',
            'items.*.quantity' => 'required|integer|min:1',
            'voucher_code' => 'nullable|string',
            'delivery_method' => 'required|in:delivery,pickup',
            'shipping_zone_id' => 'nullable|integer',
        ];
    }

    private function quoteResponse(array $q): array
    {
        return collect($q)->except(['lines', 'voucher'])->all() + [
            'voucher_code' => $q['voucher']?->code,
            'items' => collect($q['lines'])->map(fn ($l) => [
                'product_id' => $l['product']->id,
                'name' => $l['product']->name,
                'price' => $l['price'],
                'quantity' => $l['quantity'],
                'subtotal' => $l['subtotal'],
            ])->all(),
        ];
    }

    public function quote(Request $r, CheckoutService $svc)
    {
        $d = $r->validate($this->quoteRules());

        return $this->quoteResponse($svc->quote($d['items'], $d['voucher_code'] ?? null, $d['delivery_method'], $d['shipping_zone_id'] ?? null));
    }

    public function checkout(Request $r, CheckoutService $svc)
    {
        $d = $r->validate($this->quoteRules() + [
            'address_id' => 'required_if:delivery_method,delivery|nullable|exists:addresses,id',
            'payment_method' => 'required|in:cod,transfer,qris,ewallet',
            'note' => 'nullable|string',
        ]);

        $address = null;
        if ($d['delivery_method'] === 'delivery') {
            $address = Address::where('user_id', $r->user()->id)->findOrFail($d['address_id']);
            $d['shipping_zone_id'] = $address->shipping_zone_id;
        }

        return DB::transaction(function () use ($svc, $d, $r, $address) {
            $q = $svc->quote($d['items'], $d['voucher_code'] ?? null, $d['delivery_method'], $d['shipping_zone_id'] ?? null);

            $order = Order::create([
                'code' => 'KA'.now()->format('ymd').strtoupper(substr(uniqid(), -5)),
                'user_id' => $r->user()->id,
                'delivery_method' => $d['delivery_method'],
                'recipient' => $address?->recipient,
                'phone' => $address?->phone,
                'address' => $address?->full_address,
                'shipping_zone_id' => $d['shipping_zone_id'] ?? null,
                'subtotal' => $q['subtotal'],
                'discount' => $q['discount'],
                'shipping_fee' => $q['shipping_fee'],
                'total' => $q['total'],
                'voucher_code' => $q['voucher']?->code,
                'payment_method' => $d['payment_method'],
                'note' => $d['note'] ?? null,
            ]);

            foreach ($q['lines'] as $l) {
                $order->items()->create([
                    'product_id' => $l['product']->id,
                    'name' => $l['product']->name,
                    'price' => $l['price'],
                    'quantity' => $l['quantity'],
                    'subtotal' => $l['subtotal'],
                ]);
                $l['product']->decrement('stock', $l['quantity']);
                $l['product']->increment('sold_count', $l['quantity']);
            }
            $q['voucher']?->increment('used_count');

            return $order->load('items');
        });
    }

    public function orders(Request $r)
    {
        return $r->user()->orders()->with('items')->latest()->paginate(20);
    }

    public function order(Request $r, Order $order)
    {
        abort_unless($order->user_id === $r->user()->id, 403);

        return $order->load('items');
    }

    public function cancelOrder(Request $r, Order $order)
    {
        abort_unless($order->user_id === $r->user()->id, 403);
        abort_unless($order->status === 'pending', 422, 'Pesanan sudah diproses dan tidak bisa dibatalkan.');
        DB::transaction(function () use ($order) {
            foreach ($order->items as $i) {
                Product::whereKey($i->product_id)->increment('stock', $i->quantity);
                Product::whereKey($i->product_id)->decrement('sold_count', $i->quantity);
            }
            $order->update(['status' => 'cancelled']);
        });

        return $order->fresh('items');
    }

    // ---------- Admin Toko via Aplikasi HP ----------
    public function adminOrders(Request $r)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $q = Order::with(['items', 'user'])->latest();
        if ($r->filled('status') && $r->status !== 'all') {
            $q->where('status', $r->status);
        }

        return $q->paginate(30);
    }

    public function updateOrderStatus(Request $r, Order $order)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $data = $r->validate([
            'status' => 'nullable|in:pending,processing,delivering,completed,cancelled',
            'payment_status' => 'nullable|in:unpaid,paid',
        ]);

        if (isset($data['status'])) {
            $order->status = $data['status'];
        }
        if (isset($data['payment_status'])) {
            $order->payment_status = $data['payment_status'];
        }
        $order->save();

        return $order->load(['items', 'user']);
    }

    public function adminStats(Request $r)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $today = now()->startOfDay();

        return [
            'pending_count' => Order::where('status', 'pending')->count(),
            'processing_count' => Order::where('status', 'processing')->count(),
            'delivering_count' => Order::where('status', 'delivering')->count(),
            'today_orders_count' => Order::where('created_at', '>=', $today)->count(),
            'today_income' => (int) Order::where('created_at', '>=', $today)->where('status', '!=', 'cancelled')->sum('total'),
        ];
    }

    public function adminProducts(Request $r)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $q = Product::with('category')->latest();
        if ($r->filled('category_id')) {
            $q->where('category_id', $r->category_id);
        }
        if ($r->filled('q')) {
            $q->where('name', 'like', '%'.$r->q.'%');
        }

        return $q->get();
    }

    public function adminStoreProduct(Request $r)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $data = $r->validate([
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'unit' => 'required|string|max:30',
            'price' => 'required|integer|min:0',
            'promo_price' => 'nullable|integer|min:0',
            'stock' => 'required|integer|min:0',
            'description' => 'nullable|string',
            'is_flash_sale' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'photo' => 'nullable|image|max:5120',
            'image' => 'nullable|string',
        ]);

        if ($r->hasFile('photo')) {
            $data['image'] = $r->file('photo')->store('products', 'public');
        }

        unset($data['photo']);
        $product = Product::create($data);

        return $product->load('category');
    }

    public function adminUpdateProduct(Request $r, Product $product)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $data = $r->validate([
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'unit' => 'required|string|max:30',
            'price' => 'required|integer|min:0',
            'promo_price' => 'nullable|integer|min:0',
            'stock' => 'required|integer|min:0',
            'description' => 'nullable|string',
            'is_flash_sale' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'photo' => 'nullable|image|max:5120',
            'image' => 'nullable|string',
        ]);

        if ($r->hasFile('photo')) {
            $data['image'] = $r->file('photo')->store('products', 'public');
        }

        unset($data['photo']);
        $product->update($data);

        return $product->fresh('category');
    }

    public function adminDestroyProduct(Request $r, Product $product)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $product->delete();

        return ['message' => 'ok'];
    }

    public function adminToggleProduct(Request $r, Product $product)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $product->is_active = ! $product->is_active;
        $product->save();

        return $product->load('category');
    }

    public function adminGetSettings(Request $r)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        return [
            'store_name' => Setting::get('store_name', 'Kios Aisyha'),
            'store_whatsapp' => Setting::get('store_whatsapp', '6282154306904'),
            'store_phone' => Setting::get('store_phone', '0821-5430-6904'),
            'store_hours' => Setting::get('store_hours', '07:00 - 21:00 WIB'),
            'store_address' => Setting::get('store_address', 'Jl. Kios Aisyha, Pusat Sembako Segar'),
            'store_bank_name' => Setting::get('store_bank_name', 'BCA'),
            'store_bank_account' => Setting::get('store_bank_account', ''),
            'store_bank_holder' => Setting::get('store_bank_holder', 'Kios Aisyha'),
            'store_qris_image' => Setting::get('store_qris_image') ? asset('storage/'.Setting::get('store_qris_image')) : null,
            'store_qris_name' => Setting::get('store_qris_name', 'Kios Aisyha'),
            'free_shipping_min' => (int) Setting::get('free_shipping_min', 150000),
            'default_shipping_fee' => (int) Setting::get('default_shipping_fee', 8000),
        ];
    }

    public function adminUpdateSettings(Request $r)
    {
        abort_unless($r->user()->isAdmin(), 403, 'Akses khusus admin.');

        $keys = [
            'store_name', 'store_whatsapp', 'store_phone', 'store_hours',
            'store_address', 'store_bank_name', 'store_bank_account',
            'store_bank_holder', 'store_qris_name', 'free_shipping_min', 'default_shipping_fee',
        ];
        foreach ($keys as $k) {
            if ($r->has($k)) {
                Setting::put($k, $r->input($k));
            }
        }

        if ($r->hasFile('qris_photo')) {
            $path = $r->file('qris_photo')->store('qris', 'public');
            Setting::put('store_qris_image', $path);
        }

        return $this->adminGetSettings($r);
    }
}

