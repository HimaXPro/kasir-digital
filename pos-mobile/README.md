# Kasir Digital - Flutter Mobile App

Aplikasi mobile POS (Point of Sale) yang terhubung ke Laravel backend secara realtime.

## 🏗️ Arsitektur

```
Flutter Mobile App ←── REST API (HTTP + Sanctum Token) ──→ Laravel Backend ←── MySQL
```

Data antara **web browser** dan **HP** adalah **realtime & sinkron** karena keduanya mengakses database MySQL yang sama.

## 📱 Fitur

| Screen | Deskripsi |
|--------|-----------|
| **Login** | Autentikasi dengan email & password (Laravel Sanctum token) |
| **Dashboard** | KPI hari ini, grafik omzet 7 hari, produk terlaris, transaksi terbaru |
| **Kasir POS** | Grid produk, cart, diskon, pilih metode bayar, proses transaksi |
| **Produk** | CRUD produk dengan search & filter kategori |
| **Laporan** | Ringkasan penjualan & grafik |
| **Kategori** | CRUD kategori via bottom sheet |

## ⚙️ Setup

### 1. Konfigurasi URL Backend

Edit `lib/core/services/api_service.dart`:

```dart
// Untuk emulator Android (Laravel di localhost)
const String kBaseUrl = 'http://10.0.2.2:8000/api';

// Untuk device fisik (ganti dengan IP komputer Anda)
const String kBaseUrl = 'http://192.168.1.100:8000/api';

// Untuk production
const String kBaseUrl = 'https://yourdomain.com/api';
```

### 2. Jalankan Laravel Backend

```bash
cd pos-web
php artisan serve
```

### 3. Jalankan Flutter App

```bash
cd pos-mobile
flutter pub get
flutter run
```

## 🎨 Design System

UI Flutter **mengikuti desain web app** dengan palette warna yang sama:

| Token | Warna | Hex |
|-------|-------|-----|
| Primary (Indigo) | `AppTheme.primary` | `#4F46E5` |
| Accent (Cyan) | `AppTheme.accent` | `#06B6D4` |
| Success (Green) | `AppTheme.success` | `#10B981` |
| Warning (Amber) | `AppTheme.warning` | `#F59E0B` |
| Sidebar BG | `AppTheme.sidebarBg` | `#0F172A` |

## 📦 Dependencies

```yaml
http: ^1.2.1              # HTTP requests ke Laravel API
shared_preferences: ^2.3.2 # Simpan token lokal
google_fonts: ^6.2.1      # Inter font
fl_chart: ^0.69.0         # Bar chart, Line chart
intl: ^0.19.0             # Format Rupiah
provider: ^6.1.2          # State management
```

## 🔐 Autentikasi

App menggunakan **Laravel Sanctum** token-based authentication:
1. Login → Laravel return token
2. Token disimpan di `SharedPreferences`
3. Setiap request HTTP include header `Authorization: Bearer {token}`
4. Logout → token dihapus dari server dan lokal

## 📡 API Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/api/auth/login` | Login, return token |
| POST | `/api/auth/logout` | Logout, revoke token |
| GET | `/api/dashboard` | Data dashboard (KPI, chart, dll) |
| GET | `/api/products` | List produk (paginasi + search) |
| POST | `/api/products` | Tambah produk baru |
| PUT | `/api/products/{id}` | Update produk |
| DELETE | `/api/products/{id}` | Hapus produk |
| GET | `/api/categories` | List kategori |
| POST | `/api/categories` | Tambah kategori |
| PUT | `/api/categories/{id}` | Update kategori |
| DELETE | `/api/categories/{id}` | Hapus kategori |
| POST | `/api/transactions` | Proses transaksi POS |
