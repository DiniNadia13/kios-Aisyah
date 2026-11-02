<?php

namespace App\Filament\Resources\Products\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Schema;

class ProductInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('category_id')
                    ->numeric(),
                TextEntry::make('name'),
                TextEntry::make('description')
                    ->placeholder('-')
                    ->columnSpanFull(),
                ImageEntry::make('image')
                    ->placeholder('-'),
                TextEntry::make('unit'),
                TextEntry::make('price')
                    ->money(),
                TextEntry::make('promo_price')
                    ->money()
                    ->placeholder('-'),
                TextEntry::make('promo_starts_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('promo_ends_at')
                    ->dateTime()
                    ->placeholder('-'),
                IconEntry::make('is_flash_sale')
                    ->boolean(),
                TextEntry::make('stock')
                    ->numeric(),
                TextEntry::make('min_stock')
                    ->numeric(),
                TextEntry::make('sold_count')
                    ->numeric(),
                IconEntry::make('is_active')
                    ->boolean(),
                TextEntry::make('created_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('updated_at')
                    ->dateTime()
                    ->placeholder('-'),
            ]);
    }
}
