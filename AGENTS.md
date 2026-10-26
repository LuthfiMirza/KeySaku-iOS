# 🤖 AGENTS.md — Konvensi Kode & Panduan Arsitektur KeySaku iOS

Dokumen ini adalah pedoman wajib bagi AI Agent (di Anti-Gravity IDE / Cursor) dalam menulis, memodifikasi, dan membangun kode untuk **KeySaku iOS**.

## 1. Prinsip Utama Arsitektur
1. **100% Native Apple Frameworks (Zero Third-Party Libraries):**
   - DILARANG menambahkan dependensi CocoaPods atau Swift Package Manager (SPM) eksternal.
   - Gunakan murni framework bawaan iOS 17+: `SwiftUI`, `SwiftData`, `Charts`, `Speech`, `AVFoundation`, `Security` (Keychain), dan `Foundation` (`URLSession`).
2. **Arsitektur Hybrid Offline-First + Laravel API Sync:**
   - **Sumber Kebenaran UI (Single Source of Truth):** Seluruh tampilan SwiftUI membaca data langsung dari **SwiftData (`@Query`)** agar aplikasi terasa instan (0ms latency) dan tetap berfungsi penuh saat *offline*.
   - **Sinkronisasi Latar Belakang (`SyncService`):** Setiap aksi tambah/edit/hapus disimpan ke `SwiftData` terlebih dahulu (dengan flag `isSynced = false` dan `remoteId: Int?`), lalu dikirim secara asinkron (`Task { await SyncService.shared.sync() }`) ke backend **Laravel 12 KeySaku** jika tersedia koneksi internet.
3. **Xcode 16+ Synchronized Folders:**
   - Semua kode sumber `.swift` WAJIB diletakkan di dalam direktori `KeySaku/` agar otomatis terdeteksi oleh Xcode tanpa perlu memodifikasi file `.xcodeproj` secara manual.

## 2. Aturan Bisnis Krusial (Wajib Konsisten dengan KeySaku Web)
1. **Auto-Update Saldo Akun (`TransactionObserver.swift`):**
   - Jangan pernah menyimpan objek `Transaction` secara langsung ke `modelContext` dari View tanpa melalui `TransactionObserver`.
   - **Saat Transaksi Dibuat:** Jika `type == .income`, tambahkan `account.balance += amount`. Jika `type == .expense`, kurangi `account.balance -= amount`.
   - **Saat Transaksi Diedit:** Kembalikan (*revert*) efek nominal & tipe lama pada akun asal terlebih dahulu, baru terapkan nominal & tipe baru pada akun tujuan.
   - **Saat Transaksi Dihapus:** Kembalikan (*revert*) saldo akun terkait sebelum memanggil `modelContext.delete(transaction)`.
2. **Aturan Status Anggaran Bulanan (`Budget`):**
   - Hitung realisasi pengeluaran (`spentAmount`) dari total transaksi bertipe `expense` pada kategori, bulan, dan tahun yang sama.
   - Persentase = `(spentAmount / limitAmount) * 100`.
   - Indikator Status:
     - **Aman (Hijau / `.green`):** `< 80%`
     - **Mendekati Batas (Kuning/Oranye / `.orange`):** `80%` s/d `< 100%`
     - **Lewat Batas (Merah / `.red`):** `>= 100%`
3. **Aturan Target Tabungan (`SavingsGoal`):**
   - Menambah kontribusi tabungan (`addContribution(amount:)`) **HANYA** menambahkan nilai `currentAmount` pada `SavingsGoal` tersebut (untuk melacak progress bar) dan **TIDAK** memotong saldo `Account` mana pun.
4. **Aturan Kategori (`Category`):**
   - Terdapat daftar **Kategori Tetap (`isDefault = true`)** yang di-seed otomatis saat instalasi awal dan tidak boleh dihapus.
   - Pengguna dapat **Menambah & Mengedit Kategori Kustom (`isDefault = false`)** baik untuk `income` maupun `expense`.

## 3. Standar Format & UI/UX
- **Mata Uang:** Seluruh nominal uang wajib diformat menggunakan `CurrencyFormatter.rupiah(amount)` menghasilkan format `Rp 20.000` (tanpa desimal `,00`).
- **Bahasa Antarmuka:** 100% Bahasa Indonesia yang ramah keluarga.
- **Kode Utuh:** Saat men-generate file `.swift`, tuliskan kode secara utuh dan lengkap. Dilarang memotong kode dengan komentar seperti `// ... kode lainnya tetap sama`.
