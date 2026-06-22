# E-Presensi — Mobile (Mahasiswa)

Aplikasi **Flutter** untuk mahasiswa melakukan **presensi berbasis lokasi (geofence)** per mata kuliah.
Backend/panel admin-nya ada di repo terpisah: **[absensi-web](https://github.com/kizadl/absensi-web)** (Laravel).

> ⚠️ Aplikasi ini **butuh backend berjalan** agar bisa login & presensi. Setup `absensi-web` dulu, baru aplikasi ini.

---

## ✨ Fitur

- Login mahasiswa (token Sanctum)
- Beranda berisi **kartu mata kuliah**
- **Presensi masuk & pulang** per matkul dengan validasi GPS (geofence) + jam pintar (tombol "Pulang" aktif sesuai jam matkul)
- Riwayat presensi per bulan
- Ikon aplikasi custom (dari `mobileAbsen.png`)

---

## 🧰 Prasyarat

| Kebutuhan | Versi | Catatan |
|-----------|-------|---------|
| **Flutter SDK** | ≥ 3.38 (Dart ≥ 3.10.8) | cek dengan `flutter --version` |
| **Android SDK** | — | lewat Android Studio, atau command-line tools |
| **Perangkat** | HP Android (USB debugging **ON**) atau emulator | |
| **Backend** | [absensi-web](https://github.com/kizadl/absensi-web) berjalan | sumber data API |

Cek kesiapan environment dengan:

```bash
flutter doctor
```

---

## 🚀 Cara Setup

```bash
# 1. Clone
git clone https://github.com/kizadl/absensi-mobile.git
cd absensi-mobile

# 2. Ambil dependency
flutter pub get
```

### 3. ⭐ Konfigurasi Backend URL (LANGKAH PALING PENTING)

Edit file **`lib/config/env.dart`** → ubah `baseUrl` sesuai cara HP/emulator-mu terhubung ke backend:

| Skenario | `baseUrl` | Langkah tambahan |
|----------|-----------|------------------|
| **Emulator Android** | `http://10.0.2.2:8000/api` | — (10.0.2.2 = localhost PC dari emulator) |
| **HP fisik via kabel USB** | `http://127.0.0.1:8000/api` | jalankan `adb reverse tcp:8000 tcp:8000` tiap colok HP |
| **HP fisik, WiFi sama dgn PC** | `http://<IP-LAN-PC>:8000/api` | jalankan backend: `php artisan serve --host=0.0.0.0`, IP cek `ipconfig` |
| **Backend sudah online (hosting)** | `https://<domain-kamu>/api` | — |

> Contoh isi `lib/config/env.dart`:
> ```dart
> class Env {
>   Env._();
>   static const String baseUrl = 'http://10.0.2.2:8000/api'; // sesuaikan!
> }
> ```

> Cleartext HTTP (`http://`) sudah diizinkan di `AndroidManifest.xml` untuk dev lokal, jadi tidak perlu setting tambahan.

### 4. Jalankan

```bash
flutter devices                 # pastikan HP/emulator terbaca
flutter run                     # jalankan ke perangkat yang terhubung
```

### 5. (Opsional) Build APK untuk dibagikan

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

> ❗ Kalau APK dibagikan ke orang lain, `baseUrl` harus mengarah ke backend yang **bisa dijangkau HP mereka** (hosting online, atau WiFi yang sama). `127.0.0.1`/`10.0.2.2` hanya jalan di HP yang terhubung ke PC pengembang.

---

## 🔑 Login (akun seeder)

| Login | Password |
|-------|----------|
| `adit` | `password` |

(Akun mahasiswa dibuat oleh seeder di [absensi-web](https://github.com/kizadl/absensi-web). Bisa tambah/ubah lewat panel admin.)

---

## 📍 Syarat presensi berhasil

1. **GPS/Lokasi HP aktif** + izin lokasi di-allow saat diminta.
2. Posisimu **dalam radius** titik kampus yang diatur admin di web → menu **Pengaturan**.
3. Presensi pulang baru aktif sesuai **jam pulang** matkul.

---

## 🎨 Ganti ikon aplikasi

Ikon diambil dari `mobileAbsen.png` (root project) memakai `flutter_launcher_icons`.
Kalau gambar diganti, generate ulang dengan:

```bash
dart run flutter_launcher_icons
```

---

## 🧯 Troubleshooting

- **Login gagal / "Terjadi kesalahan jaringan"** → backend tidak terjangkau. Cek: server `php artisan serve` jalan, `baseUrl` benar, `adb reverse` sudah dijalankan (kalau USB).
- **HP tidak terbaca `flutter devices`** → aktifkan **USB debugging** (Opsi pengembang), pasang driver USB, cek `adb devices`.
- **Presensi selalu "di luar radius"** → atur titik kampus ke lokasimu di web → **Pengaturan**, perbesar radius.
- **Build error cache (Windows)** → `flutter clean` lalu `flutter pub get` (project sudah set `kotlin.incremental=false` di `gradle.properties`).

---

## 📦 Tech stack

Flutter · Dart · Provider · Dio · Geolocator · Geocoding · flutter_secure_storage · intl
