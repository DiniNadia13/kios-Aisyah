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

Route::get('/download', function () {
    $path = base_path('../KiosAisyha.apk');
    if (! file_exists($path)) {
        abort(404, 'File APK belum tersedia.');
    }
    return response()->download($path, 'KiosAisyha.apk', [
        'Content-Type' => 'application/vnd.android.package-archive',
    ]);
});
