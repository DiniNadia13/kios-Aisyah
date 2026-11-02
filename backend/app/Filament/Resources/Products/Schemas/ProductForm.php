<?php

namespace App\Filament\Resources\Products\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ProductForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Produk')->columns(2)->schema([
                    Select::make('category_id')->label('Kategori')
                        ->relationship('category', 'name')->required()->searchable()->preload(),
                    TextInput::make('name')->label('Nama produk')->required(),
                    Select::make('unit')->label('Satuan')->required()->default('pcs')
                        ->options(['pcs' => 'pcs', 'kg' => 'kg', 'liter' => 'liter', 'karton' => 'karton', 'bungkus' => 'bungkus', 'sak' => 'sak']),
                    TextInput::make('price')->label('Harga normal')->required()->numeric()->prefix('Rp'),
                    Textarea::make('description')->label('Deskripsi')->columnSpanFull(),
                    FileUpload::make('image')->label('Foto')->image()->disk('public')->directory('products'),
                    Toggle::make('is_active')->label('Aktif')->default(true),
                ]),
                Section::make('Promo (opsional, diisi admin)')
                    ->description('Isi harga promo + jadwal untuk menampilkan harga coret. Centang Flash Sale agar muncul di bagian Flash Sale beranda.')
                    ->columns(2)->schema([
                        TextInput::make('promo_price')->label('Harga promo')->numeric()->prefix('Rp')->lt('price'),
                        Toggle::make('is_flash_sale')->label('Tampilkan di Flash Sale'),
                        DateTimePicker::make('promo_starts_at')->label('Mulai'),
                        DateTimePicker::make('promo_ends_at')->label('Berakhir'),
                    ]),
                Section::make('Stok')->columns(3)->schema([
                    TextInput::make('stock')->label('Stok')->required()->numeric()->default(0),
                    TextInput::make('min_stock')->label('Stok minimum (peringatan)')->required()->numeric()->default(5),
                    TextInput::make('sold_count')->label('Terjual')->numeric()->default(0)->disabled(),
                ]),
            ]);
    }
}
