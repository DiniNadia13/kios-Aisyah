<?php

use App\Http\Controllers\Api\ShopController;
use Illuminate\Support\Facades\Route;

// Publik
Route::post('/register', [ShopController::class, 'register']);
Route::post('/login', [ShopController::class, 'login']);
Route::get('/home', [ShopController::class, 'home']);
Route::get('/categories', [ShopController::class, 'categories']);
Route::get('/products', [ShopController::class, 'products']);
Route::get('/products/{product}', [ShopController::class, 'product']);
Route::get('/vouchers', [ShopController::class, 'vouchers']);
Route::get('/shipping-zones', [ShopController::class, 'shippingZones']);
Route::get('/cart-upsell', [ShopController::class, 'cartUpsell']);
Route::post('/cart/quote', [ShopController::class, 'quote']);

// Perlu login
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [ShopController::class, 'me']);
    Route::post('/logout', [ShopController::class, 'logout']);

    Route::get('/addresses', [ShopController::class, 'addresses']);
    Route::post('/addresses', [ShopController::class, 'storeAddress']);
    Route::delete('/addresses/{address}', [ShopController::class, 'destroyAddress']);

    Route::post('/checkout', [ShopController::class, 'checkout']);
    Route::get('/orders', [ShopController::class, 'orders']);
    Route::get('/orders/{order}', [ShopController::class, 'order']);
    Route::post('/orders/{order}/cancel', [ShopController::class, 'cancelOrder']);

    // Admin Toko via Aplikasi HP
    Route::get('/admin/orders', [ShopController::class, 'adminOrders']);
    Route::post('/admin/orders/{order}/status', [ShopController::class, 'updateOrderStatus']);
    Route::get('/admin/stats', [ShopController::class, 'adminStats']);
    Route::get('/admin/products', [ShopController::class, 'adminProducts']);
    Route::post('/admin/products', [ShopController::class, 'adminStoreProduct']);
    Route::post('/admin/products/{product}', [ShopController::class, 'adminUpdateProduct']);
    Route::delete('/admin/products/{product}', [ShopController::class, 'adminDestroyProduct']);
    Route::post('/admin/products/{product}/toggle', [ShopController::class, 'adminToggleProduct']);
    Route::get('/admin/settings', [ShopController::class, 'adminGetSettings']);
    Route::post('/admin/settings', [ShopController::class, 'adminUpdateSettings']);
});
