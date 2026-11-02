<?php

namespace App\Filament\Resources\Vouchers\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class VoucherForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('code')->label('Kode voucher')->required()->unique(ignoreRecord: true)
                    ->dehydrateStateUsing(fn ($state) => strtoupper($state)),
                TextInput::make('description')->label('Keterangan'),
                Select::make('type')->label('Jenis potongan')->required()->default('fixed')
                    ->options(['fixed' => 'Nominal (Rp)', 'percent' => 'Persen (%)']),
                TextInput::make('value')->label('Nilai potongan')->required()->numeric(),
                TextInput::make('max_discount')->label('Maks. potongan (Rp)')->numeric(),
                TextInput::make('min_purchase')->label('Minimal belanja (Rp)')->required()->numeric()->default(0),
                TextInput::make('quota')->label('Kuota pemakaian')->numeric(),
                TextInput::make('used_count')->label('Sudah dipakai')->numeric()->default(0)->disabled(),
                DateTimePicker::make('starts_at')->label('Mulai'),
                DateTimePicker::make('ends_at')->label('Berakhir'),
                Toggle::make('is_active')->label('Aktif')->default(true),
            ]);
    }
}
