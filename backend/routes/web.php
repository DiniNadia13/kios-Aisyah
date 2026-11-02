<?php

use App\Models\Order;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/receipt/{order:code}', function (Order $order) {
    $order->load(['items', 'user']);
    return view('receipt', compact('order'));
})->name('receipt.show');
