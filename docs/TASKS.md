# ✅ Action Plan & Tasks — KeySaku iOS (Start dari 0 di AG IDE)

Gunakan daftar tugas berurutan ini untuk mengeksekusi pembuatan kode **KeySaku iOS** dari nol hingga selesai.

## Milestone 1 (M1) — Foundation & Data Layer
- [x] **Task 1.1:** Buat helper `Utilities/CurrencyFormatter.swift` (format Rupiah `Rp X.XXX` dan helper tanggal Bahasa Indonesia) serta `Utilities/KeychainHelper.swift`.
- [x] **Task 1.2:** Buat kelima model SwiftData di `Models/`: `Account.swift`, `Category.swift`, `Transaction.swift`, `Budget.swift`, dan `SavingsGoal.swift` beserta model `User.swift`.
- [x] **Task 1.3:** Buat `Services/DatabaseSeeder.swift` untuk mengisi Kategori Tetap (`Makanan & Minuman`, `Transportasi`, `Belanja`, `Tagihan`, `Gaji`, dll.) dan Akun awal saat aplikasi pertama kali dijalankan.
- [x] **Task 1.4:** Buat kerangka navigasi utama `Views/Layout/MainTabView.swift` (Tab Dashboard, Transaksi, Anggaran, Tabungan, Laporan/Akun) dan konfigurasikan `.modelContainer` di `KeySakuApp.swift`.

## Milestone 2 (M2) — Auth (Laravel API) & Manajemen Akun
- [x] **Task 2.1:** Buat `Services/APIConfig.swift` dan `Services/AuthService.swift` (Login, Register, Logout via `URLSession` ke backend Laravel + Mode Offline Bypass agar tetap bisa dipakai tanpa server).
- [x] **Task 2.2:** Buat tampilan `Views/Auth/LoginView.swift` dan `Views/Auth/RegisterView.swift` dengan desain modern khas iOS.
- [x] **Task 2.3:** Buat `Views/Accounts/ManageAccountsView.swift` dan `AccountFormSheet.swift` untuk CRUD akun keuangan (`Kas`, `Bank`, `E-Wallet`) beserta perhitungan total saldo otomatis.

## Milestone 3 (M3) — Transaksi, Auto-Update Saldo & Kategori Kustom
- [x] **Task 3.1:** Buat `Services/TransactionObserver.swift` yang menangani `createTransaction`, `updateTransaction`, dan `deleteTransaction` secara atomik (otomatis memperbarui `account.balance`).
- [x] **Task 3.2:** Buat `Views/Categories/ManageCategoriesView.swift` untuk melihat kategori tetap dan menambah/mengedit kategori baru.
- [x] **Task 3.3:** Buat `Views/Transactions/TransactionListView.swift` lengkap dengan filter Bulan/Tahun, filter Kategori, pencarian, dan *swipe-to-delete* dengan konfirmasi.
- [x] **Task 3.4:** Buat `Views/Transactions/CreateEditTransactionSheet.swift` untuk form tambah & edit pemasukan/pengeluaran.

## Milestone 4 (M4) — Anggaran Bulanan & Target Tabungan
- [x] **Task 4.1:** Buat `Views/Budgets/ManageBudgetsView.swift` dan `BudgetFormSheet.swift` dengan perhitungan persentase real-time dan indikator status:
  - Hijau (`Aman` < 80%), Oranye (`Mendekati Batas` 80–99%), Merah (`Lewat Batas` >= 100%).
- [x] **Task 4.2:** Implementasikan fitur **Salin Anggaran Bulan Lalu** dengan 1 klik di `ManageBudgetsView.swift`.
- [x] **Task 4.3:** Buat `Views/Goals/ManageGoalsView.swift`, `GoalFormSheet.swift`, dan `AddContributionSheet.swift` (menambah nominal `currentAmount` pada progress bar tabungan tanpa memotong saldo akun).

## Milestone 5 (M5) — Voice Input Pintar & Laporan Visual (Swift Charts)
- [x] **Task 5.1:** Buat `Services/VoiceParserService.swift` menggunakan `SFSpeechRecognizer(locale: Locale(identifier: "id-ID"))` dan parser angka Bahasa Indonesia (*"Beli makan siang dua puluh ribu"* ➔ `Rp 20.000`, kategori otomatis).
- [x] **Task 5.2:** Buat `Views/Transactions/VoiceTransactionSheet.swift` dengan animasi gelombang mikrofon, hasil transkripsi live, dan tombol simpan instan.
- [x] **Task 5.3:** Buat `Views/Reports/ReportsChartView.swift` menggunakan framework `Charts` bawaan Apple:
  - Grafik Batang (`BarMark`) pemasukan vs pengeluaran 6 bulan terakhir.
  - Grafik Donat (`SectorMark`) pengeluaran per kategori bulan ini.
- [x] **Task 5.4:** Lengkapi `Views/Dashboard/DashboardView.swift` dengan kartu ringkasan saldo, ringkasan anggaran keseluruhan, tombol cepat Input Suara, dan kartu Insight otomatis.

## Milestone 6 (M6) — Cloud Sync Laravel & Polish
- [ ] **Task 6.1:** Buat `Services/SyncService.swift` untuk sinkronisasi dua arah antara `SwiftData` lokal di iPhone dan endpoint REST API `/api/v1/sync` di server Laravel Hostinger.
- [ ] **Task 6.2:** Tambahkan *Haptic Feedback* pada aksi penting, fitur Export/Backup JSON lokal, serta panduan penambahan route `routes/api.php` untuk sisi server Laravel 12.
