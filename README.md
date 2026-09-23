# Cepaty

[![CI](https://github.com/januarsyah901/cepaty/actions/workflows/ci.yml/badge.svg)](https://github.com/januarsyah901/cepaty/actions/workflows/ci.yml)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.8%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/januarsyah901/cepaty)](https://github.com/januarsyah901/cepaty/releases)

**Cepaty** adalah aplikasi menu bar macOS native yang ringan dan efisien untuk memantau kecepatan unduh (download) dan unggah (upload) per aplikasi secara *real-time*.

Aplikasi ini berjalan sebagai *menu bar accessory*, tidak memenuhi Dock, dan tidak membutuhkan akses `sudo`, `root`, maupun modul ekstensi kernel pihak ketiga.

---

## Fitur Utama

- **Live Speed di Menu Bar**: Menampilkan total kecepatan unduh dan unggah secara langsung (`↓ …  ↑ …`) dengan tipografi monospaced agar angka stabil saat berubah.
- **Rincian Lalu Lintas Per Aplikasi**: Memetakan koneksi jaringan ke aplikasi terkait, lengkap dengan nama proses dan ikon aplikasi bawaan macOS.
- **Pengelompokan Helper & Renderer**: Proses turunan (seperti Google Chrome Helper atau Slack Renderer) otomatis digabungkan ke aplikasi induknya.
- **Dua Mode Pengurutan**: Pilihan urutan berdasarkan kecepatan aktif saat ini (**Sekarang**) atau akumulasi penggunaan data selama sesi berjalan (**Total**).
- **Efisiensi Daya & CPU Ekstrem**: Konsumsi CPU **0.0%** pada kondisi latar belakang (background) dan rata-rata memori hanya ~45 MB.
- **Buka Saat Login**: Integrasi langsung dengan API resmi macOS `SMAppService`.
- **Privasi Terjaga**: Berjalan 100% lokal di mesin pengguna, tidak memodifikasi paket jaringan, dan tanpa telemetri luar.

---

## Arsitektur Teknis

Cepaty dirancang dengan fokus pada efisiensi baterai dan akurasi data.

```
                  ┌────────────────────────┐
                  │    macOS Network      │
                  │   (/usr/bin/nettop)    │
                  └───────────┬────────────┘
                              │ Snapshot 25ms (-L 1)
                              ▼
                  ┌────────────────────────┐
                  │     NettopSampler      │  (Background Queue)
                  └───────────┬────────────┘
                              │ Parsed Samples
                              ▼
                  ┌────────────────────────┐
                  │   TrafficAggregator    │  (Delta & Baseline Calc)
                  └───────────┬────────────┘
                              │ Resolved App Traffic
                              ▼
                  ┌────────────────────────┐
                  │    TrafficViewModel    │  (Main Thread State)
                  └───────────┬────────────┘
                              │ Reactive Updates
              ┌───────────────┴───────────────┐
              ▼                               ▼
     ┌─────────────────┐             ┌─────────────────┐
     │   MenuBarLabel  │             │ TrafficPopover  │
     └─────────────────┘             └─────────────────┘
```

### Mengapa Menggunakan Snapshot Diskrit?

Utilitas bawaan `nettop` pada macOS versi terbaru memiliki *issue* berupa *spin loop* konsumsi CPU tinggi jika dijalankan dalam mode streaming terus-menerus (`-L 0`).

Cepaty menyelesaikan kendala ini dengan pendekatan **periodic snapshot**:
1. Menjalankan `nettop -P -n -x -L 1 -J bytes_in,bytes_out` setiap interval waktu (5 detik saat ditutup, 1 detik saat popover dibuka).
2. Setiap proses snapshot hanya membutuhkan waktu eksekusi sekitar 25 milidetik di latar belakang, lalu proses tersebut langsung selesai.
3. Selisih byte (delta) dan laju per detik dihitung langsung oleh [TrafficAggregator.swift](Sources/Cepaty/Core/TrafficAggregator.swift).
4. Hasilnya, CPU Mac tetap dingin, hemat baterai, dan bebas dari proses *hanging*.

---

## Persyaratan Sistem

- macOS 13.0 (Ventura) atau versi lebih baru (Sonoma, Sequoia, dsb).
- Mendukung arsitektur Apple Silicon (M1/M2/M3/M4) dan Intel (x86_64).

---

## Instalasi

### 1. Unduh DMG (Praktis)

1. Buka halaman [Releases](https://github.com/januarsyah901/cepaty/releases).
2. Unduh berkas `Cepaty-1.0.0.dmg`.
3. Buka DMG dan seret `Cepaty.app` ke folder `Applications`.
4. Jalankan aplikasi dari Launchpad atau Spotlight.

### 2. Kompilasi dari Source

Pastikan Xcode Command Line Tools sudah terpasang di Mac:

```bash
# Clone repositori
git clone https://github.com/januarsyah901/cepaty.git
cd cepaty

# Jalankan pengujian unit
./build.sh test

# Bangun aplikasi dan buat paket installer DMG
./package_app.sh
```

Aplikasi `Cepaty.app` akan otomatis dikompilasi, diberi signature ad-hoc, dan dipasang langsung ke `/Applications`.

---

## Struktur Berkas

```text
cepaty/
├── Package.swift               # Definisi Swift Package
├── build.sh                    # Skrip kompilasi dan runner unit test
├── package_app.sh              # Skrip pembuat bundle .app dan .dmg
├── AppIcon.icns                # Ikon aplikasi resolusi tinggi
├── Sources/
│   └── Cepaty/
│       ├── CepatyApp.swift     # Titik masuk SwiftUI MenuBarExtra
│       ├── Core/
│       │   ├── AppResolver.swift       # Pemetaan PID & icon aplikasi
│       │   ├── NettopParser.swift      # Parser output CSV nettop
│       │   ├── NettopSampler.swift     # Timer eksekusi snapshot nettop
│       │   ├── TrafficAggregator.swift # Kalkulator delta & agregasi data
│       │   └── TrafficModels.swift     # Struktur data model
│       ├── ViewModels/
│       │   └── TrafficViewModel.swift  # Pengelola status tampilan
│       ├── Views/
│       │   ├── AppRow.swift            # Baris data per aplikasi
│       │   ├── MenuBarLabel.swift      # Label kecepatan di status bar
│       │   └── TrafficPopover.swift    # Jendela popover utama
│       └── Utils/
│           ├── ByteFormatter.swift     # Format satuan B, KB, MB, GB
│           └── LaunchAtLogin.swift     # Pengaturan login service
├── Tests/
│   └── CepatyTests/
│       ├── Main.swift          # Runner pengujian unit
│       └── TrafficTests.swift  # Kumpulan skenario unit test
└── .github/
    └── workflows/
        └── ci.yml              # CI workflow GitHub Actions
```

---

## Pengujian Unit

Cepaty dilengkapi dengan rangkaian unit test independen tanpa ketergantungan framework eksternal:

```bash
./build.sh test
```

Rangkaian pengujian mencakup:
- Validasi parser nama proses dengan spasi dan tanda titik.
- Penanganan baris rusak atau format tidak valid.
- Verifikasi proteksi baseline awal dan kalkulasi delta.
- Pembersihan nilai kecepatan saat proses berhenti beraktivitas.
- Logika pengurutan data (kecepatan saat ini vs total sesi).

---

## Lisensi

Proyek ini dilisensikan di bawah ketentuan [MIT License](LICENSE).
