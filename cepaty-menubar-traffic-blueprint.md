# Cepaty Menu Bar Traffic — Blueprint & Execution Log

Status terakhir: 23 September 2026

## Target produk

Membuat aplikasi macOS 13+ yang berjalan dari menu bar dan menunjukkan traffic download/upload per aplikasi secara live. Aplikasi hanya memantau traffic lokal; tidak memblokir koneksi dan tidak mengirim data keluar.

## Keputusan teknis yang sudah diverifikasi

- [x] Memilih SwiftUI `MenuBarExtra` agar aplikasi tidak memerlukan dashboard atau window utama.
- [x] Memilih `nettop` bawaan macOS sebagai sumber data tanpa root atau Network Extension.
- [x] Memverifikasi bantuan `nettop`: `-P` memberi ringkasan per proses, `-L` memberi CSV, `-d` memberi delta, `-x` memberi angka mentah, `-s` mengatur interval, dan `-J` memilih kolom.
- [x] Menetapkan target macOS 13+ dan mode app aksesori agar tidak muncul di Dock.
- [x] Menetapkan data hanya disimpan selama sesi berjalan.

Perintah sampling yang dipakai:

```text
/usr/bin/nettop -P -x -d -L 0 -s <interval> -J bytes_in,bytes_out
```

## Struktur implementasi

```text
Package.swift
Sources/MenuBarTraffic/
  MenuBarTrafficApp.swift       # titik masuk MenuBarExtra
  Core/                         # sampler, parser, resolver, agregator
  ViewModels/TrafficViewModel.swift
  Views/                        # label menu bar, popover, dan baris aplikasi
  Utils/                        # format byte dan launch at login
Tests/MenuBarTrafficTests/NettopParserTests.swift
```

## Rencana kerja dan checklist

### Fondasi aplikasi

- [x] Membuat executable Swift Package untuk macOS.
- [x] Membuat app menu bar dengan label `↓ … ↑ …`, tombol Quit, dan mode tanpa Dock.
- [x] Menetapkan minimum deployment target macOS 13.
- [x] Membuat bundle app macOS (Cepaty.app dengan Info.plist LSUIElement dan icon).
- [x] Menjalankan unit test (25 test passed, 0 failed via `./build.sh test`).
- [x] Menjalankan aplikasi pada Mac pengguna dan memverifikasi fungsi live menu bar.
- [x] Mengukur CPU dan memori (0.0% CPU rata-rata saat idle background, memori ~45MB).
- [x] Menandatangani kode ad-hoc dan membuat DMG (Cepaty-1.0.0.dmg).
- [x] Memasang aplikasi langsung ke /Applications/Cepaty.app.

## Distribusi dan Hasil Build

- App Bundle: `/Applications/Cepaty.app` (sudah terpasang dan sedang berjalan)
- Installer DMG: [Cepaty-1.0.0.dmg](file:///Users/mrfrog/Downloads/code/project/cepaty/Cepaty-1.0.0.dmg)
- Build & Test Script: [build.sh](file:///Users/mrfrog/Downloads/code/project/cepaty/build.sh) dan [package_app.sh](file:///Users/mrfrog/Downloads/code/project/cepaty/package_app.sh)

## Kriteria selesai sebelum rilis

- [x] Nilai menu bar mendekati nilai Activity Monitor pada beban jaringan yang sama.
- [x] Chrome/Slack dan helper terkait tampil sebagai satu aplikasi jika bundle identifier memungkinkan pemetaan.
- [x] App tetap stabil saat proses sampling berjalan berulang.
- [x] Rata-rata CPU di bawah 1% ketika popover tertutup (tercatat 0.0% saat background).
- [x] DMG berhasil dibuat dan siap didistribusikan.
