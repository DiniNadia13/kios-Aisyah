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
    $candidates = [
        public_path('KiosAisyha.apk'),
        __DIR__ . '/../../public_html/KiosAisyha.apk',
        base_path('../public_html/KiosAisyha.apk'),
        base_path('../KiosAisyha.apk'),
        base_path('KiosAisyha.apk'),
    ];
    foreach ($candidates as $p) {
        if (file_exists($p)) {
            return response()->download($p, 'KiosAisyha.apk', [
                'Content-Type' => 'application/vnd.android.package-archive',
            ]);
        }
    }
    return redirect('/KiosAisyha.apk');
});
