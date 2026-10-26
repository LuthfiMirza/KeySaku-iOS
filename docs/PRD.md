# 📄 Product Requirements Document (PRD) — KeySaku iOS

## 1. Visi Produk
Membangun ulang (**1:1 Feature Parity Rebuild**) aplikasi **KeySaku** dari platform Web PWA (Laravel 12 + Livewire) menjadi aplikasi **iOS Native (SwiftUI + SwiftData)** yang terhubung dengan database server KeySaku melalui REST API, memberikan pengalaman pencatatan keuangan keluarga tercepat di iPhone.

---

## 2. Spesifikasi Modul & Fitur

### Modul 1: Autentikasi & Sinkronisasi (Milestone 2 & 6)
- **Login & Register:**
  - Form Login (Email & Password) dan Register (Nama, Email, Password, Konfirmasi Password).
  - Mengirim request ke endpoint Laravel `/api/v1/login` dan `/api/v1/register`.
  - Menyimpan token autentikasi Laravel Sanctum ke dalam **iOS Keychain**.
  - Menyediakan *Mode Offline / Demo Lokal* jika server belum dikonfigurasi, sehingga aplikasi tetap dapat diuji coba secara penuh di perangkat.
- **Sinkronisasi Data (`SyncService`):**
  - Saat berhasil login atau melakukan *pull-to-refresh* di Dashboard, aplikasi mengambil data Akun, Kategori, Transaksi, Anggaran, dan Target Tabungan dari server MySQL Hostinger dan memperbarui `SwiftData` lokal.

### Modul 2: Manajemen Akun Keuangan (Milestone 2)
- Mendukung 3 tipe akun: **Kas (`Kas`)**, **Bank (`Bank`)**, dan **E-Wallet (`E-Wallet`)**.
- Menampilkan daftar akun beserta total saldo gabungan seluruh akun di bagian atas.
- Operasi CRUD Akun: Tambah akun baru (Nama, Tipe, Saldo Awal, Warna/Ikon), Edit nama/tipe akun, dan Hapus akun (dengan peringatan bahwa transaksi terkait akan ikut terhapus).

### Modul 3: Transaksi & Kategori (Milestone 3)
- **Kategori Tetap + Kustom:**
  - *Default Expense:* Makanan & Minuman, Belanja Keluarga, Transportasi, Tagihan & Utilitas, Pendidikan, Kesehatan, Hiburan, Lainnya.
  - *Default Income:* Gaji, Bonus, Hasil Usaha, Investasi, Lainnya.
  - Pengguna dapat menambah kategori baru beserta memilih ikon SF Symbols.
- **Pencatatan Transaksi (CRUD):**
  - Input: Tipe (`Pemasukan` / `Pengeluaran`), Nominal (`Rp`), Kategori, Akun Keuangan, Tanggal, dan Catatan/Deskripsi.
  - *Auto-update saldo:* Setiap transaksi yang disimpan/diedit/dihapus langsung memperbarui saldo akun terkait melalui `TransactionObserver`.
- **Filter & Riwayat:**
  - Filter berdasarkan **Bulan & Tahun** serta **Kategori**.
  - Pencarian berdasarkan judul/catatan transaksi.
  - Edit transaksi via *tap*, dan Hapus transaksi via *swipe-to-delete* dengan dialog konfirmasi (`confirmationDialog`).

### Modul 4: Input Suara Pintar / Voice Transaction (Milestone 5)
- Menggunakan `SFSpeechRecognizer(locale: Locale(identifier: "id-ID"))`.
- Pengguna menekan tombol mikrofon dan mengucapkan kalimat natural, contoh:
  - *"Beli makan siang dua puluh ribu"* ➔ Tipe: `Pengeluaran`, Judul: `"Beli makan siang"`, Nominal: `20000`, Kategori: `"Makanan & Minuman"`.
  - *"Bayar listrik seratus lima puluh ribu"* ➔ Tipe: `Pengeluaran`, Judul: `"Bayar listrik"`, Nominal: `150000`, Kategori: `"Tagihan & Utilitas"`.
  - *"Terima gaji lima juta"* ➔ Tipe: `Pemasukan`, Judul: `"Terima gaji"`, Nominal: `5000000`, Kategori: `"Gaji"`.
- Menampilkan pratinjau hasil *parsing* di layar agar pengguna dapat memilih akun atau mengoreksi sebelum menekan **Simpan**, atau memilih mode **Simpan Otomatis**.

### Modul 5: Anggaran Bulanan / Budgets (Milestone 4)
- Menetapkan batas anggaran (`limitAmount`) per kategori pengeluaran untuk bulan & tahun tertentu.
- Menampilkan progress bar pemakaian anggaran secara *real-time* berdasarkan transaksi bulan tersebut:
  - **Aman (`< 80%`):** Warna Hijau, badge `"Aman"`.
  - **Mendekati Batas (`80% – 99%`):** Warna Kuning/Oranye, badge `"Mendekati Batas"`.
  - **Lewat Batas (`>= 100%`):** Warna Merah, badge `"Lewat Batas"`.
- **Fitur Salin Anggaran Bulan Lalu:** Tombol 1-klik untuk menyalin seluruh daftar anggaran dari bulan sebelumnya ke bulan berjalan.

### Modul 6: Target Tabungan / Savings Goals (Milestone 4)
- Membuat target tabungan dengan atribut: Nama Goal, Nominal Target (`targetAmount`), Nominal Terkumpul (`currentAmount`), dan Tenggat Waktu (`deadline`).
- Menampilkan *progress bar* visual, persentase capaian (`%`), dan sisa kekurangan dana.
- **Tambah Kontribusi:** Sheet cepat untuk menambahkan nominal uang ke `currentAmount` kapan saja (hanya menambah progress bar tabungan tanpa memotong saldo akun).

### Modul 7: Dashboard, Laporan & Insight (Milestone 5)
- **Dashboard Utama:**
  - Kartu Total Saldo Keluarga + ringkasan Pemasukan & Pengeluaran bulan berjalan.
  - Tombol Aksi Cepat: **+ Catat Transaksi** dan **🎤 Input Suara**.
  - Ringkasan kesehatan anggaran keseluruhan & daftar 5 transaksi terbaru.
  - Kartu **Insight Otomatis** (contoh: *"Pengeluaran terbesar bulan ini ada di kategori Makanan & Minuman sebesar Rp 1.200.000"* atau peringatan jika ada kategori yang melewati batas anggaran).
- **Halaman Laporan (`Swift Charts`):**
  - **Grafik Batang (`BarMark`):** Perbandingan Pemasukan vs Pengeluaran selama **6 bulan terakhir**.
  - **Grafik Donat (`SectorMark`):** Proporsi pengeluaran per kategori pada bulan yang dipilih.
