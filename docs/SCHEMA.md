# 🗄️ Database & API Schema — KeySaku iOS

Dokumen ini mendefinisikan skema penyimpanan lokal **SwiftData** di iPhone serta kontrak JSON REST API untuk sinkronisasi dengan database MySQL **KeySaku Web (Laravel 12)**.

---

## 1. Skema Model SwiftData (`KeySaku/Models/`)

### 1.1 `Account` (Akun Keuangan)
| Field | Tipe Swift | Keterangan |
|---|---|---|
| `id` | `UUID` | Primary key lokal (`@Attribute(.unique)`) |
| `remoteId` | `Int?` | ID dari tabel `accounts` di MySQL Laravel |
| `name` | `String` | Nama akun (contoh: "Kas Rumah", "BCA", "GoPay") |
| `type` | `String` | `"Kas"`, `"Bank"`, atau `"E-Wallet"` |
| `balance` | `Double` | Saldo saat ini (diperbarui otomatis oleh `TransactionObserver`) |
| `icon` | `String` | Nama SF Symbol (`banknote`, `building.columns`, `wallet.pass`) |
| `colorHex` | `String` | Kode warna kartu akun |
| `isSynced` | `Bool` | Status sinkronisasi ke server Laravel |
| `transactions` | `[Transaction]` | Relasi `@Relationship(deleteRule: .cascade, inverse: \Transaction.account)` |

### 1.2 `Category` (Kategori Tetap & Kustom)
| Field | Tipe Swift | Keterangan |
|---|---|---|
| `id` | `UUID` | Primary key lokal (`@Attribute(.unique)`) |
| `remoteId` | `Int?` | ID dari tabel `categories` di MySQL Laravel |
| `name` | `String` | Nama kategori (contoh: "Makanan & Minuman") |
| `type` | `String` | `"income"` atau `"expense"` |
| `icon` | `String` | SF Symbol kategori |
| `colorHex` | `String` | Warna visual kategori untuk grafik donat |
| `isDefault` | `Bool` | `true` untuk kategori bawaan sistem, `false` untuk tambahan user |
| `isSynced` | `Bool` | Status sinkronisasi |

### 1.3 `Transaction` (Transaksi Pemasukan & Pengeluaran)
| Field | Tipe Swift | Keterangan |
|---|---|---|
| `id` | `UUID` | Primary key lokal (`@Attribute(.unique)`) |
| `remoteId` | `Int?` | ID dari tabel `transactions` di MySQL Laravel |
| `title` | `String` | Deskripsi singkat transaksi |
| `amount` | `Double` | Nominal transaksi (> 0) |
| `type` | `String` | `"income"` atau `"expense"` |
| `categoryName` | `String` | Nama kategori terkait |
| `date` | `Date` | Tanggal transaksi |
| `note` | `String` | Catatan opsional |
| `isSynced` | `Bool` | Status sinkronisasi |
| `account` | `Account?` | Relasi ke model `Account` |

### 1.4 `Budget` (Anggaran Bulanan)
| Field | Tipe Swift | Keterangan |
|---|---|---|
| `id` | `UUID` | Primary key lokal (`@Attribute(.unique)`) |
| `remoteId` | `Int?` | ID dari tabel `budgets` di MySQL Laravel |
| `categoryName` | `String` | Nama kategori pengeluaran |
| `limitAmount` | `Double` | Batas anggaran bulanan |
| `month` | `Int` | Bulan (`1` - `12`) |
| `year` | `Int` | Tahun (contoh: `2026`) |
| `isSynced` | `Bool` | Status sinkronisasi |

### 1.5 `SavingsGoal` (Target Tabungan)
| Field | Tipe Swift | Keterangan |
|---|---|---|
| `id` | `UUID` | Primary key lokal (`@Attribute(.unique)`) |
| `remoteId` | `Int?` | ID dari tabel `goals` di MySQL Laravel |
| `title` | `String` | Nama target tabungan (contoh: "Dana Darurat Keluarga") |
| `targetAmount` | `Double` | Nominal target |
| `currentAmount` | `Double` | Nominal terkumpul saat ini |
| `deadline` | `Date` | Tenggat waktu pencapaian |
| `icon` | `String` | SF Symbol |
| `isSynced` | `Bool` | Status sinkronisasi |

---

## 2. Kontrak Endpoint REST API Laravel 12 (`/api/v1/...`)

Aplikasi iOS berkomunikasi menggunakan header `Accept: application/json` dan `Authorization: Bearer <token>`:

- `POST /api/v1/login` ➔ Body: `{ email, password }` ➔ Response: `{ token, user: { id, name, email } }`
- `POST /api/v1/register` ➔ Body: `{ name, email, password, password_confirmation }` ➔ Response: `{ token, user }`
- `POST /api/v1/logout` ➔ Menghapus token Sanctum aktif
- `GET /api/v1/sync` ➔ Mengambil seluruh data user (`accounts`, `categories`, `transactions`, `budgets`, `goals`) dalam 1 request JSON
- `POST /api/v1/sync` ➔ Mengirim batch perubahan lokal (`isSynced == false`) dari iPhone ke MySQL Laravel
- Endpoint CRUD individual:
  - `GET|POST|PUT|DELETE /api/v1/accounts`
  - `GET|POST|PUT|DELETE /api/v1/categories`
  - `GET|POST|PUT|DELETE /api/v1/transactions`
  - `GET|POST|PUT|DELETE /api/v1/budgets`
  - `GET|POST|PUT|DELETE /api/v1/goals`
