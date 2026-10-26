# 🎨 DESIGN.md — Panduan & Spesifikasi Redesign UI/UX KeySaku iOS

Dokumen ini menjabarkan konsep, arsitektur visual, dan rencana peremajaan antarmuka (**UI/UX Redesign**) untuk **KeySaku iOS** berdasarkan referensi desain aplikasi mobile modern kelas atas (*Modern Food & Lifestyle App UI* dengan micro-interactions, elevated card elevation, organic curved headers, dan dynamic floating tab bar).

---

## 1. 🌟 Filosofi & Dekonstruksi Referensi Desain

Berdasarkan referensi visual yang diberikan, terdapat 6 pilar estetika utama yang akan diadaptasi ke dalam konteks aplikasi keuangan keluarga **KeySaku**:

```
┌────────────────────────────────────────────────────────┐
│  1. Top Curved Organic Header (Emerald Brand Gradient) │
│     Avatar • Lokasi/Status • Notifikasi / Bell         │
├────────────────────────────────────────────────────────┤
│  2. Floating Hero Card & Search/Filter Pill            │
│     Total Saldo Keluarga • Arus Kas Bulanan            │
├────────────────────────────────────────────────────────┤
│  3. Horizontal Interactive Category Strip              │
│     Pills Kategori dengan Ikon Vibran & Active State   │
├────────────────────────────────────────────────────────┤
│  4. Dynamic Highlight Carousel (Smart Financial Promo) │
│     Surplus Card • Peringatan Anggaran • Tips Hemat    │
├────────────────────────────────────────────────────────┤
│  5. 2-Column Grid Cards (Akun & Target Tabungan)       │
│     Ikon Akun/Goal • Nominal • Tombol Aksi "+" Cepat   │
├────────────────────────────────────────────────────────┤
│  6. Modern Floating Dock Tab Bar                       │
│     Elevated Center Action Button (🎤 Voice Input)     │
└────────────────────────────────────────────────────────┘
```

---

## 2. 🎯 Pemetaan Komponen: Dari Referensi ke KeySaku iOS

| Elemen Referensi | Implementasi di KeySaku iOS | Fungsi & Keunggulan |
|---|---|---|
| **Top Header Hijau Melengkung** | Organic Curved Header di `DashboardView` | Memberikan identitas warna khas KeySaku (Emerald `#10B981` ke `#059669`) dengan avatar pengguna & status koneksi cloud/offline. |
| **Search Pill "Search restaurants"** | Floating Quick Search & Filter Bar | Mencari transaksi atau menyaring akun & kategori secara instan. |
| **Promo Banner Carousel ("Fast & Free Delivery")** | **Smart Financial Insights Carousel** | Kartu carousel swipeable untuk notifikasi anggaran, pencapaian target tabungan, dan tips surplus kas. |
| **Horizontal Category Pills ("All, Burger, Pizza")** | **Kategori Strip Interaktif** | Tombol kapsul horizontal untuk filter transaksi cepat (`Semua`, `Makanan`, `Bensin`, `Belanja`, `Tagihan`, `Gaji`). |
| **2-Column Grid Cards (Menu McDonald's + Tombol "+")** | **2-Column Cards untuk Akun & Goals** | Menampilkan Akun (`Kas`, `BCA`, `GoPay`) dan Target Tabungan dalam 2 kolom rapi dengan tombol bulat hijau **"+"** untuk aksi instan. |
| **List Menu Vertikal dengan Badge Kalori/Waktu** | **Daftar Transaksi Terbaru Berdesain Modern** | Kartu transaksi rounded dengan badge tipe (Pemasukan/Pengeluaran), ikon berwarna, dan tanggal relatif. |
| **Floating Bottom Tab Bar dengan Badge Cart** | **Custom Floating Tab Bar** | Tab bar melayang dengan efek glassmorphism/blur dan tombol **Mikrofon Suara 🎤** yang menonjol di tengah (*Elevated Floating Action Button*). |

---

## 3. 🎨 Design System & Visual Tokens

### 3.1 Palet Warna (Color Palette)
- **Primary Brand (Emerald Green):**
  - Gradient Start: `#10B981` (Emerald 500)
  - Gradient End: `#059669` (Emerald 600)
  - Accent Soft: `Color(hex: "#10B981").opacity(0.15)`
- **Secondary / Action Accent:**
  - Blue Tint: `#3B82F6` (Investasi & Info)
  - Amber / Warning: `#F59E0B` (Mendekati Batas Anggaran)
  - Coral Red: `#EF4444` (Pengeluaran & Lewat Batas)
- **Neutral & Surface Colors:**
  - Card Surface (Light): `#FFFFFF` dengan shadow lembut `Color.black.opacity(0.04)`
  - Card Surface (Dark): `Color(.secondarySystemBackground)`
  - Background (Light): `#F8FAFC` / `Color(.systemGroupedBackground)`
  - Border Subtil: `Color(.separator).opacity(0.4)`

### 3.2 Tipografi & Geometri
- **Font:** SF Pro Rounded (Desain ramah keluarga, angka terasa empuk dan modern).
  - Headline Saldo: `.system(size: 30, weight: .bold, design: .rounded)`
  - Section Header: `.headline.weight(.bold)`
  - Badges & Chips: `.caption2.weight(.bold)`
- **Border Radii:**
  - Large Hero Card: `24pt`
  - Grid Item Card: `20pt`
  - Buttons & Quick Chips: `Capsule()` atau `14pt`
  - Floating Action Button: `Circle()`

---

## 4. 📱 Rencana Tampilan Halaman (Screen Breakdown)

### 4.1 Dashboard (Home) Baru
1. **Header Lengkung Organik:**
   - Avatar Profil pengguna di kiri atas.
   - Sapaan hangat: *"Halo, Keluarga Mirza"* + Badge status: *"🟢 Tersambung"*.
   - Ikon Notifikasi / Pengaturan di kanan atas.
2. **Hero Saldo Mengambang (Floating Card):**
   - Menampilkan total saldo gabungan seluruh akun.
   - Mini chip pemasukan bulanan (Hijau) & pengeluaran bulanan (Merah) di dalam kartu hero.
3. **Smart Insight Carousel (Swipeable Banner):**
   - Kartu 1: *“Keren! Surplus kas bulan ini Rp 2.500.000. Yuk tabung sekarang.”*
   - Kartu 2: *“Perhatian: Anggaran Kategori 'Belanja' sudah terpakai 88%.”*
   - Kartu 3: *“Target Tabungan 'Liburan Akhir Tahun' kurang Rp 1.500.000 lagi!”*
4. **Kategori Strip Horizontal:**
   - Pilihan kategori cepat dengan ikon SF Symbol dan warna unik.
5. **Bagian Akun Keuangan (2-Column Grid):**
   - Meniru gaya card referensi: Logo bank/dompet di atas, nama akun, saldo besar, dan tombol bulat hijau **"+"** di pojok kanan bawah kartu untuk mencatat langsung dari akun tersebut.
6. **Bagian Target Tabungan (Mini Progress Cards):**
   - Kartu progres dengan persentase melingkar atau progress bar halus + tombol tambah kontribusi cepat.
7. **Riwayat Transaksi Terbaru:**
   - 5 transaksi terakhir dengan visual rapi, divider subtil, dan navigasi *"Lihat Semua"*.

### 4.2 Custom Floating Tab Bar
Tab bar konvensional iOS digantikan dengan **Floating Island Dock**:
- Latar belakang kapsul mengambang dengan efek *Ultra Thin Material* (Glassmorphism).
- Item navigasi:
  1. 🏠 **Home (Dashboard)**
  2. 💳 **Transaksi**
  3. 🎤 **Input Suara Pintar (Center Elevated Button)** — Tombol hijau menyala di tengah yang melayang lebih tinggi untuk mencatat instan dengan suara.
  4. 📊 **Anggaran**
  5. 📈 **Laporan**

---

## 5. 🛠 Rencana Langkah Eksekusi (Implementation Steps)

1. **Step 1:** Buat komponen visual reusable:
   - `CurvedHeaderShape.swift`: Shape lengkung organik di bagian atas.
   - `GridAccountCard.swift`: Kartu 2-kolom akun dengan tombol aksi cepat.
   - `FloatingTabBar.swift`: Custom Tab Bar mengambang dengan elevated mic button.
2. **Step 2:** Perbarui `DashboardView.swift` mengadopsi struktur baru (Header lengkung, Hero card, Insight carousel, 2-column grid akun).
3. **Step 3:** Integrasikan micro-animations (spring animations saat tap, haptic feedback saat tombol diklik).
4. **Step 4:** Validasi build di Xcode & uji tampilan di Simulator iPhone 17 Pro.
