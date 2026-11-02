<?php

namespace App\Filament\Resources\Banners\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class BannerForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('title')->label('Judul')->required(),
                FileUpload::make('image')->label('Gambar banner')->image()->required()
                    ->disk('public')->directory('banners'),
                Select::make('placement')->label('Posisi tayang')->required()->default('home_top')
                    ->options(['home_top' => 'Beranda atas (carousel)', 'popup' => 'Pop-up saat aplikasi dibuka']),
                Select::make('link_type')->label('Tujuan saat diklik')
                    ->options(['product' => 'Produk', 'category' => 'Kategori', 'voucher' => 'Voucher', 'url' => 'Link']),
                TextInput::make('link_value')->label('ID produk / ID kategori / kode voucher / URL'),
                TextInput::make('sort_order')->label('Urutan')->required()->numeric()->default(0),
                DateTimePicker::make('starts_at')->label('Mulai tayang'),
                DateTimePicker::make('ends_at')->label('Selesai tayang'),
                Toggle::make('is_active')->label('Aktif')->default(true),
            ]);
    }
}
