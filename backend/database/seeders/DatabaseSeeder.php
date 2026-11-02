<?php

namespace Database\Seeders;

use App\Models\Banner;
use App\Models\Category;
use App\Models\Product;
use App\Models\Setting;
use App\Models\User;
use App\Models\Voucher;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Akun Admin (Bisa login dengan nomor WhatsApp pemilik toko atau default)
        User::updateOrCreate(['phone' => '082154306904'], [
            'name' => 'Admin Kios Aisyha',
            'email' => 'admin@kiosaisyha.local',
            'password' => 'admin123',
            'role' => 'admin',
        ]);
        User::updateOrCreate(['phone' => '081200000000'], [
            'name' => 'Admin Demo',
            'email' => 'demo@kiosaisyha.local',
            'password' => 'admin123',
            'role' => 'admin',
        ]);

        // 2. Pengaturan Toko & Ongkir
        Setting::put('free_shipping_min', 150000); // Belanja >= 150rb gratis ongkir
        Setting::put('default_shipping_fee', 8000);  // Tarif standar jika di bawah 150rb
        Setting::put('store_name', 'Kios Aisyha');
        Setting::put('store_phone', '081200000000');
        Setting::put('store_hours', '07:00 - 21:00 WIB');
        Setting::put('delivery_time', '30 - 45 Menit');
        Setting::put('store_whatsapp', '6282154306904');
        Setting::put('store_phone', '0821-5430-6904');
        Setting::put('store_address', 'Jl. Pemuda Sembako No. 8, Kios Aisyha');
        Setting::put('store_bank_name', 'BCA');
        Setting::put('store_bank_account', '82154306904');
        Setting::put('store_bank_holder', 'Kios Aisyha');
        Setting::put('store_qris_name', 'Kios Aisyha (QRIS Dinamis / Statis)');

        // 3. Banner Promo Beranda
        Banner::updateOrCreate(['title' => 'Gratis Ongkir Belanja Sembako'], [
            'image' => 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=800&q=80',
            'placement' => 'home_top',
            'link_type' => 'voucher',
            'link_value' => 'HEMAT10',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        Banner::updateOrCreate(['title' => 'Paket Sembako Berkah Hemat'], [
            'image' => 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=800&q=80',
            'placement' => 'home_top',
            'link_type' => 'category',
            'link_value' => '1',
            'sort_order' => 2,
            'is_active' => true,
        ]);

        // 4. Voucher Promo (Admin yang kelola)
        Voucher::updateOrCreate(['code' => 'HEMAT10'], [
            'description' => 'Potongan Rp 10.000 belanja sembako',
            'type' => 'fixed',
            'value' => 10000,
            'min_purchase' => 100000,
            'quota' => 50,
            'is_active' => true,
        ]);

        Voucher::updateOrCreate(['code' => 'AISYHA5K'], [
            'description' => 'Diskon Rp 5.000 tanpa syarat ribet',
            'type' => 'fixed',
            'value' => 5000,
            'min_purchase' => 50000,
            'quota' => 100,
            'is_active' => true,
        ]);

        // 5. Data Khusus Sembako (Tanpa sayur)
        $data = [
            'Paket Hemat Sembako' => [
                ['Paket Berkah Aisyha (Beras 5kg + Minyak 2L + Gula 1kg + Teh)', 'paket', 135000, 125000, true],
                ['Paket Dapur Hemat (Minyak 1L + Terigu 1kg + Telur 1kg + Garam)', 'paket', 65000, 59000, true],
            ],
            'Beras' => [
                ['Beras Premium Ramos 5 kg', 'sak', 74000, null, false],
                ['Beras Pulen Setra 5 kg', 'sak', 71000, 68000, false],
                ['Beras Wangi Pandan 5 kg', 'sak', 78000, null, false],
            ],
            'Minyak Goreng' => [
                ['Minyak Goreng Bimoli 2 Liter', 'pouch', 38000, null, false],
                ['Minyak Goreng Tropical 2 Liter', 'botol', 39000, 36500, true],
                ['Minyak Goreng Sania 1 Liter', 'pouch', 19000, null, false],
            ],
            'Gula & Pemanis' => [
                ['Gula Pasir Gulaku Kuning 1 kg', 'kg', 18000, null, false],
                ['Gula Pasir Kristal Putih 1 kg', 'kg', 17500, null, false],
                ['Gula Merah Aren Asli 500 g', 'bungkus', 15000, null, false],
            ],
            'Tepung & Olahan' => [
                ['Tepung Terigu Segitiga Biru 1 kg', 'kg', 13000, null, false],
                ['Tepung Beras Rose Brand 500 g', 'bungkus', 8500, null, false],
                ['Tepung Maizena Pilihan 200 g', 'kotak', 6000, null, false],
            ],
            'Telur Ayam' => [
                ['Telur Ayam Negeri Segar 1 kg', 'kg', 29000, 27500, false],
                ['Telur Ayam Kampung Asli 10 butir', 'mika', 28000, null, false],
                ['Telur Puyuh Pilihan 30 butir', 'mika', 16000, null, false],
            ],
            'Mie & Makanan Instan' => [
                ['Indomie Goreng Spesial', 'pcs', 3500, null, false],
                ['Indomie Kuah Ayam Bawang', 'pcs', 3500, null, false],
                ['Bihun Jagung Padamu 4 keping', 'bungkus', 6500, null, false],
                ['Sarden ABC Saus Tomat 155 g', 'kaleng', 11500, null, false],
            ],
            'Bumbu Dapur' => [
                ['Garam Dapur Beriodium 250 g', 'bungkus', 3000, null, false],
                ['Kecap Manis Bango 520 ml', 'pouch', 23000, 21000, false],
                ['Penyedap Rasa Royco Ayam 230 g', 'pouch', 11000, null, false],
                ['Saus Sambal Dua Belibis 340 ml', 'botol', 18000, null, false],
            ],
            'Kopi, Teh & Susu' => [
                ['Kopi Kapal Api Spesial Mix 10 sachet', 'renceng', 14000, null, false],
                ['Teh Celup Sariwangi 25 kantong', 'kotak', 7500, null, false],
                ['Susu Kental Manis Frisian Flag Cokelat 370 g', 'kaleng', 13000, null, false],
            ],
            'Kebersihan Rumah' => [
                ['Sabun Cuci Piring Sunlight Jeruk Nipis 650 ml', 'pouch', 14500, 13000, false],
                ['Deterjen Bubuk Rinso Molto 770 g', 'bungkus', 22000, null, false],
            ],
        ];

        $i = 0;
        foreach ($data as $cat => $products) {
            $c = Category::updateOrCreate(['name' => $cat], ['sort_order' => $i++]);
            foreach ($products as [$name, $unit, $price, $promoPrice, $isFlash]) {
                Product::updateOrCreate(['name' => $name], [
                    'category_id' => $c->id,
                    'unit' => $unit,
                    'price' => $price,
                    'promo_price' => $promoPrice,
                    'promo_starts_at' => $promoPrice ? now()->subDay() : null,
                    'promo_ends_at' => $promoPrice ? now()->addDays(7) : null,
                    'is_flash_sale' => $isFlash,
                    'stock' => 150,
                    'sold_count' => rand(15, 120),
                ]);
            }
        }
    }
}
