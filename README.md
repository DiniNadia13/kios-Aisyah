# Kios Aisyha

Aplikasi belanja sembako: `backend/` (Laravel + panel admin Filament) dan `app/` (Flutter, Android & iOS).

## Menjalankan backend
```
cd backend
C:\xampp83\php\php.exe artisan migrate --seed
C:\xampp83\php\php.exe artisan serve --host=0.0.0.0 --port=8000
```
- Panel admin: http://127.0.0.1:8000/admin  (login seed: `admin@kiosaisyha.local` / `admin123` — **ganti!**)
- API: http://127.0.0.1:8000/api
- Database default SQLite; untuk MySQL XAMPP ubah `DB_*` di `backend/.env`.

## Admin mengatur
- **Promo**: Produk (harga promo + jadwal + Flash Sale), Banner (carousel/pop-up), Voucher.
- **Ongkir**: menu Shipping Zones (isi area & tarif nanti). Batas gratis ongkir: menu Settings, key `free_shipping_min` (default 150000).

## Menjalankan aplikasi
```
cd app
flutter create --project-name kios_aisyha --org id.kiosaisyha --platforms android,ios .
flutter pub get
flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api
```
Build iOS memerlukan Mac + Xcode.

