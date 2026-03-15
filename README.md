# Mansur Exercise Point — Gym Visitor Management App

Aplikasi Android untuk manajemen pengunjung & member gym, dibangun dengan **Flutter** — ringan, cepat, dan bisa digunakan tanpa internet.

---

## Tentang Aplikasi

**Mansur Exercise Point** adalah aplikasi kasir & manajemen gym berbasis mobile yang dirancang untuk mempermudah pencatatan pengunjung harian maupun member bulanan. Semua data tersimpan secara lokal di perangkat menggunakan SQLite, sehingga tetap bisa digunakan meski tanpa koneksi internet.

Aplikasi ini cocok untuk gym kecil hingga menengah yang membutuhkan sistem manajemen sederhana namun lengkap dengan fitur cetak struk via printer Bluetooth.

---

## Fitur Utama

| Fitur | Keterangan |
| --- | --- |
| Pendaftaran | Catat pengunjung harian (Rp 15.000) atau daftarkan member bulanan (Rp 300.000) |
| Check-in Member | Cari member dan lakukan check-in dengan notifikasi otomatis |
| Daftar Member | Lihat semua member aktif beserta sisa hari berlangganan |
| Laporan | Laporan pemasukan harian, mingguan, dan bulanan lengkap dengan grafik |
| Pengaturan | Konfigurasi printer Bluetooth, harga tiket, WiFi password, dan format struk |
| Cetak Struk | Print struk ke thermal printer 58mm via koneksi Bluetooth |
| Notifikasi | Notifikasi lokal otomatis setiap transaksi berhasil dicatat |
| Offline-First | Database SQLite lokal — tidak butuh internet sama sekali |

---

## Teknologi yang Digunakan

- **Framework**: Flutter 3.0+ (Dart)
- **Database**: SQLite via `sqflite`
- **State Management**: `provider`
- **Notifikasi**: `flutter_local_notifications`
- **Grafik**: `fl_chart`
- **Printer Bluetooth**: `flutter_thermal_printer`
- **UI**: Material Design 3

---

## Struktur Project

```
lib/
├── main.dart
├── models/          # Data model (Member, Transaction)
├── providers/       # State management (Provider)
├── screens/         # Halaman UI aplikasi
├── services/        # Database, Bluetooth, Notifikasi
└── widgets/         # Komponen UI yang dapat digunakan ulang
```

---

## Cara Menjalankan

### Prasyarat

- Flutter SDK `>=3.0.0`
- Android device / emulator (API 21+)
- Bluetooth thermal printer 58mm *(opsional, untuk fitur cetak struk)*

### Langkah-langkah

```bash
# 1. Clone repository
git clone https://github.com/Alectha/Mansur-Exercise-Point---Gym-Visitor-Management-App.git
cd Mansur-Exercise-Point---Gym-Visitor-Management-App

# 2. Install dependencies
flutter pub get

# 3. Jalankan aplikasi
flutter run
```

### Build APK

```bash
flutter build apk --release
```

File APK akan tersedia di: `build/app/outputs/flutter-apk/app-release.apk`

---

## Koneksi Printer Bluetooth

1. Aktifkan Bluetooth di perangkat Android
2. Pair thermal printer 58mm melalui Settings Android
3. Buka menu **Pengaturan** di aplikasi
4. Klik **Cari Printer**, pilih printer dari daftar
5. Klik **Hubungkan** — printer siap digunakan

---

## Catatan

- Aplikasi bekerja 100% offline, tidak membutuhkan internet
- Database lokal SQLite, data tersimpan di perangkat
- Tidak ada sistem login atau autentikasi
- Tidak ada fitur QR code

---

## Lisensi

OPEN SOURCE!

