# 🌿 SIBERSIH — Flutter UI

Platform pelaporan sampah kampus berbasis poin reward.

---

## Struktur Project

```
lib/
├── main.dart                 # Entry point + Theme + Routing
└── pages/
    ├── splash_page.dart      # Animasi intro (logo + partikel + ripple)
    ├── landing_page.dart     # Halaman awal (Login / Daftar / Google)
    ├── login_page.dart       # Form login
    ├── register_page.dart    # Form registrasi
    ├── main_page.dart        # Shell dengan bottom navbar
    ├── dashboard_page.dart   # Dashboard utama + poin + quotes
    ├── laporan_sampah_page.dart  # Form laporan + kamera + popup
    ├── riwayat_page.dart     # Riwayat laporan dengan tab filter
    ├── panduan_page.dart     # Panduan step-by-step interaktif
    └── profil_page.dart      # Profil + pengaturan + dark mode
```

---

## Halaman & Fitur

### 🎬 Splash Page
- Animasi masuk logo (scale + elastic + fade)
- Partikel mengambang (CustomPainter)
- Efek ripple pulsing
- Loading dots animasi
- Transisi otomatis ke Landing (3 detik)

### 🏠 Landing Page
- Gradient background animasi berputar
- Logo floating animasi
- Staggered entry animation (logo → judul → subtitle → tombol)
- Tombol: **Masuk**, **Daftar Akun Baru**, **Lanjutkan dengan Google**
- Feature pills (Eco-Friendly, Poin Reward, Tracking)
- Hover effect pada tombol Google

### 🔐 Login & Register
- Wave curve header
- Form fields dengan prefix icon
- Toggle visibilitas password
- Loading state pada tombol
- Navigasi antar Login ↔ Register

### 📊 Dashboard
- SliverAppBar expandable dengan stats
- Animated poin counter (0 → 2850)
- Card poin: masuk, keluar, tukar
- Menu grid (4 item)
- Alur kerja Sibersih (step by step)
- Auto-rotating quotes motivasi dengan indicator dots
- Riwayat aktivitas terbaru

### 📋 Laporan Sampah
- Info banner panduan singkat
- Grid 8 jenis sampah dengan animasi seleksi
- Area foto dengan tap-to-capture (toggle demo)
- Form: berat, lokasi, catatan
- Estimasi poin live
- Popup berhasil/gagal dengan animasi elasticOut

### 📅 Riwayat
- Tab bar: Semua / Terverifikasi / Proses
- Stats header (total laporan, berat, poin)
- Expandable card per laporan
- Status badge berwarna (✅ Terverifikasi, ⏳ Menunggu, ❌ Ditolak)

### 📚 Panduan
- 6 langkah interaktif (expandable)
- Tips per langkah
- FAQ accordion
- CTA banner

### 👤 Profil
- Avatar dengan edit photo
- Points summary card
- Info pribadi (edit dialog)
- Ubah password dialog
- Toggle: Dark Mode, Notifikasi, Biometrik
- Setting bahasa
- Versi app & policy
- Logout dengan konfirmasi

---

## Cara Menjalankan

```bash
# Pastikan Flutter sudah terinstall
flutter --version

# Install dependencies
flutter pub get

# Jalankan di device/emulator
flutter run

# Atau build untuk web
flutter run -d chrome
```

---

## Tema Warna

| Elemen | Warna |
|--------|-------|
| Primary | `#1007BA` (Biru Tua) |
| Secondary | `#4C3FE8` |
| Gradient Top | `#0A05A0` |
| Gradient Bottom | `#2519D4` |
| Background Light | `#F4F6FF` |
| Background Dark | `#0F0F23` |

---

## Catatan

- Font yang direkomendasikan: **Nunito** (Google Fonts)
- Semua UI adalah dummy data (belum ada backend)
- Logika bisnis & API integration menyusul
- Animasi menggunakan Flutter native (tidak butuh package tambahan)
- Dark mode tersedia dan dapat di-toggle dari halaman Profil
