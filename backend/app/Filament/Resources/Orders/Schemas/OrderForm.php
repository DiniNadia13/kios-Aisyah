<?php

namespace App\Filament\Resources\Orders\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('code')->label('Kode')->disabled(),
                Select::make('status')->label('Status pesanan')->required()->options([
                    'pending' => 'Menunggu',
                    'processing' => 'Diproses',
                    'delivering' => 'Diantar',
                    'completed' => 'Selesai',
                    'cancelled' => 'Dibatalkan',
                ]),
                Select::make('payment_status')->label('Status bayar')->required()->options([
                    'unpaid' => 'Belum bayar', 'paid' => 'Lunas', 'failed' => 'Gagal',
                ]),
                TextInput::make('payment_method')->label('Metode bayar')->disabled(),
                TextInput::make('delivery_method')->label('Pengiriman')->disabled(),
                TextInput::make('recipient')->label('Penerima')->disabled(),
                TextInput::make('phone')->label('Telepon')->disabled(),
                Textarea::make('address')->label('Alamat')->disabled()->columnSpanFull(),
                TextInput::make('subtotal')->prefix('Rp')->disabled(),
                TextInput::make('discount')->label('Potongan')->prefix('Rp')->disabled(),
                TextInput::make('shipping_fee')->label('Ongkir')->prefix('Rp')->disabled(),
                TextInput::make('total')->prefix('Rp')->disabled(),
                TextInput::make('voucher_code')->label('Voucher')->disabled(),
                Textarea::make('note')->label('Catatan')->disabled()->columnSpanFull(),
            ]);
    }
}
