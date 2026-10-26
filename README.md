# 💰 KeySaku iOS
**Aplikasi Pengelolaan Keuangan Keluarga — Native iOS (SwiftUI + SwiftData + Laravel API Sync)**

Catat pemasukan & pengeluaran keluarga dalam hitungan detik langsung dari iPhone — dengan performa 100% Native iOS, dukungan Offline-First (`SwiftData`), dan sinkronisasi penuh ke server Web KeySaku (Laravel 12).

## 📋 Daftar Isi
- [Tentang Proyek](#-tentang-proyek)
- [Fitur Utama](#-fitur-utama)
- [Tech Stack](#-tech-stack)
- [Memulai (Setup Lokal Xcode & AG IDE)](#-memulai-setup-lokal)
- [Struktur Proyek](#-struktur-proyek)
- [Integrasi Backend Laravel (Hostinger)](#-integrasi-backend-laravel)
- [Roadmap](#-roadmap)
- [Lisensi](#-lisensi)

---

## 🏠 Tentang Proyek
**KeySaku iOS** adalah versi *native mobile* dari ekosistem **KeySaku** yang dirancang untuk membantu keluarga Indonesia mengelola keuangan sehari-hari — mencatat transaksi, memantau anggaran bulanan, dan melacak target tabungan — langsung dari iPhone dengan antarmuka **SwiftUI** yang mulus, responsif, dan terintegrasi langsung dengan database **KeySaku Web (Laravel 12)**.

### Masalah yang Diselesaikan
| Masalah | Solusi KeySaku iOS |
|---|---|
| Pencatatan keuangan manual merepotkan | Input cepat *bottom-sheet* + Input Suara Native iOS (`SFSpeechRecognizer`) |
| Tidak tahu ke mana uang pergi | Dashboard interaktif & laporan visual bulanan (`Swift Charts`) |
| Anggaran keluarga tidak terkontrol | Anggaran per kategori + indikator warna & peringatan otomatis |
| Target tabungan sulit dicapai | Progress tracker tabungan *real-time* |
| Data terpisah antara HP dan Web | Sinkronisasi otomatis antara `SwiftData` di iPhone dan MySQL di Web KeySaku |

---

## ✨ Fitur Utama

### 🔐 Autentikasi & Sinkronisasi Akun
- Login & Register menggunakan akun yang sama dengan **KeySaku Web** (Laravel Sanctum Bearer Token)
- Penyimpanan sesi aman di **iOS Keychain**
- Sinkronisasi *dua arah* (Offline-First via `SwiftData` + Cloud Sync via REST API Laravel)

### 💳 Manajemen Akun
- Kelola beberapa akun keuangan (**Kas**, **Bank**, **E-Wallet**)
- Saldo akun diperbarui otomatis secara atomik saat transaksi dibuat, diedit, atau dihapus

### 📒 Transaksi & Kategori Dinamis
- Catat pemasukan (`income`) dan pengeluaran (`expense`)
- Kategori bawaan sistem + fitur **Tambah/Edit Kategori Kustom**
- Filter riwayat transaksi berdasarkan **Bulan** dan **Kategori**
- Edit dan hapus transaksi (*swipe-to-delete*) dengan dialog konfirmasi

### 🎤 Input Suara Pintar (Milestone 5)
- Catat transaksi cukup dengan ucapan menggunakan **Apple Speech Framework (`id-ID`)**
- Parser NLP Bahasa Indonesia otomatis: *"Beli makan siang dua puluh ribu"* → transaksi langsung terbuat dengan nominal `Rp 20.000`

### 📊 Anggaran Bulanan
- Tetapkan anggaran per kategori per bulan
- Indikator status visual:
  - 🟢 **Aman:** `< 80%`
  - 🟡 **Mendekati Batas:** `80% – 99%`
  - 🔴 **Lewat Batas:** `>= 100%`
- **Salin anggaran bulan lalu** dengan satu klik
- Ringkasan anggaran keseluruhan di halaman Dashboard

### 🎯 Target Tabungan
- Buat *goal* tabungan dengan nominal target dan tenggat waktu
- Lacak *progress* dengan *progress bar* visual
- Tambah nominal kontribusi kapan saja untuk meningkatkan *progress* tabungan

### 📈 Laporan & Insight
- Grafik batang (*BarMark*) pemasukan vs. pengeluaran 6 bulan terakhir menggunakan **Apple Swift Charts**
- Grafik donat (*SectorMark*) proporsi pengeluaran per kategori
- Kartu *Insight* otomatis di Dashboard

---

## 🛠 Tech Stack
| Layer | Teknologi |
|---|---|
| **UI Framework** | SwiftUI (iOS 17+) |
| **Bahasa** | Swift 6 |
| **Local Database (Offline)** | SwiftData (`@Model`, `@Query`) |
| **Remote Backend & DB** | Laravel 12 REST API (Sanctum) + MySQL (Hostinger) |
| **Networking & Auth** | Native `URLSession` (`async/await`) + iOS `Keychain` |
| **Voice Recognition** | Apple `Speech` (`SFSpeechRecognizer`) & `AVFoundation` |
| **Charts** | Apple `Swift Charts` |
| **IDE & Build** | Anti-Gravity IDE (AG IDE) + Xcode 16+ |

---

## 🚀 Memulai (Setup Lokal)

### Prasyarat
- macOS dengan **Xcode 16+** terinstal
- **Anti-Gravity IDE (AG IDE)** untuk pengembangan kode berbantuan AI
- iPhone fisik (iOS 17.0+) atau iOS Simulator
- Server **KeySaku Web (Laravel 12)** yang berjalan di lokal (`http://localhost:8000`) atau Production (Hostinger)

### Instalasi
1. **Clone repository:**
   ```bash
   git clone https://github.com/LuthfiMirza/KeySaku-iOS.git
   cd KeySaku-iOS
   ```
2. **Buka Project:**
   Buka file `KeySaku.xcodeproj` di Xcode atau buka folder workspace ini di Anti-Gravity IDE.
3. **Jalankan Aplikasi:**
   Pilih target perangkat Simulator (misal: *iPhone 16*) atau perangkat fisik, lalu tekan tombol **Run** (`⌘R`).

---

## 📁 Struktur Proyek
```text
KeySaku-iOS/
├── KeySaku/
│   ├── KeySakuApp.swift                # Entry point aplikasi & setup ModelContainer SwiftData
│   ├── Models/                         # SwiftData @Model & Codable DTOs
│   │   ├── User.swift
│   │   ├── Account.swift
│   │   ├── Category.swift
│   │   ├── Transaction.swift
│   │   ├── Budget.swift
│   │   └── SavingsGoal.swift
│   ├── Services/                       # Business Logic, Observer & Networking
│   │   ├── APIConfig.swift             # Endpoint & konfigurasi server Laravel
│   │   ├── AuthService.swift           # Login, Register, Logout & Keychain Token
│   │   ├── SyncService.swift           # Sinkronisasi dua arah SwiftData <-> Laravel API
│   │   ├── TransactionObserver.swift   # Auto-update saldo Account saat CRUD transaksi
│   │   └── VoiceParserService.swift    # SpeechRecognizer id-ID & NLP Parser Rupiah
│   ├── Views/                          # Komponen antarmuka SwiftUI
│   │   ├── Auth/                       # LoginView, RegisterView
│   │   ├── Layout/                     # MainTabView (Bottom Bar Navigation)
│   │   ├── Dashboard/                  # DashboardView & Insight Cards
│   │   ├── Accounts/                   # ManageAccountsView, AccountFormSheet
│   │   ├── Transactions/               # TransactionListView, CreateEditTransactionSheet, VoiceTransactionSheet
│   │   ├── Categories/                 # ManageCategoriesView
│   │   ├── Budgets/                    # ManageBudgetsView & Copy Last Month
│   │   ├── Goals/                      # ManageGoalsView & AddContributionSheet
│   │   └── Reports/                    # ReportsChartView (Swift Charts Bar & Donut)
│   └── Utilities/
│       ├── CurrencyFormatter.swift     # Format Rupiah (Rp 20.000)
│       └── KeychainHelper.swift        # Penyimpanan token Sanctum aman
├── docs/                               # Dokumentasi Proyek (PRD, SCHEMA, TASKS)
├── AGENTS.md                           # Panduan arsitektur & konvensi kode untuk AI Agent
└── README.md
```

---

## 🌐 Integrasi Backend Laravel (Hostinger)
Aplikasi ini terhubung langsung dengan backend **Laravel 12 (REST API)** yang di-deploy pada hosting MySQL Hostinger:
- **Autentikasi:** Laravel Sanctum API Token disimpan pada Keychain.
- **Sinkronisasi Otomatis:** Perubahan transaksi dikirim secara asinkron ke endpoint `/api/v1/sync`.
- **Mode Demo / Offline:** Jika backend belum dikonfigurasi, pengguna tetap dapat menggunakan aplikasi secara lokal (100% fungsional via SwiftData).

---

## 🗺 Roadmap
| Milestone | Status | Keterangan |
|---|---|---|
| **M1 — Foundation** | ⏳ Planned | Xcode scaffold, SwiftData container, layout MainTabView, CurrencyFormatter, Seed kategori tetap |
| **M2 — Auth & Akun** | ⏳ Planned | Login/Register (Laravel Sanctum API + Keychain), manajemen akun keuangan (Kas, Bank, E-Wallet) |
| **M3 — Transaksi & Kategori** | ⏳ Planned | CRUD transaksi, auto-update saldo (TransactionObserver), kategori tetap + kustom, filter bulan & kategori |
| **M4 — Anggaran & Tabungan** | ⏳ Planned | Anggaran bulanan (Aman/Mendekati/Lewat), salin bulan lalu 1-klik, target tabungan + progress bar |
| **M5 — Voice & Insight** | ⏳ Planned | Input suara Bahasa Indonesia (SFSpeechRecognizer), laporan Swift Charts (Bar 6 bulan & Donat), insight otomatis |
| **M6 — Sync Polish & Deploy** | ⏳ Planned | Sinkronisasi penuh SwiftData <-> MySQL Hostinger, Haptic feedback, build ke iPhone pribadi |

---

## 📄 Lisensi
Proyek ini menggunakan lisensi MIT.

Dibuat dengan ❤️ untuk keluarga Indonesia.