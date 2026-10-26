# 🚀 Panduan Integrasi REST API Laravel 12 — KeySaku Server (Hostinger)

Dokumen ini adalah panduan lengkap implementasi sisi server (backend Laravel 12) untuk menghubungkan aplikasi iOS **KeySaku** dengan database MySQL di server Hostinger melalui REST API berbasis Laravel Sanctum.

---

## 1. Konfigurasi Routes (`routes/api.php`)

Tambahkan route berikut pada file `routes/api.php` di proyek Laravel 12 Anda:

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SyncController;

/*
|--------------------------------------------------------------------------
| KeySaku API v1 Routes
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {
    // Public Auth Routes
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);

    // Protected Routes (Harus Mengirimkan Header 'Authorization: Bearer <token>')
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/user', function (Request $request) {
            return response()->json(['user' => $request->user()]);
        });

        // 2-Way Batch Sync Endpoint (Digunakan oleh KeySaku iOS SyncService)
        Route::get('/sync', [SyncController::class, 'pull']);
        Route::post('/sync', [SyncController::class, 'push']);
    });
});
```

---

## 2. Implementasi `SyncController.php` (`app/Http/Controllers/Api/SyncController.php`)

Controller ini menangani pengunduhan seluruh data user (`GET /sync`) dan penerimaan batch data offline dari iPhone (`POST /sync`):

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\Budget;
use App\Models\SavingsGoal;

class SyncController extends Controller
{
    /**
     * GET /api/v1/sync
     * Mengambil seluruh data user untuk sinkronisasi ke SwiftData iPhone
     */
    public function pull(Request $request)
    {
        $user = $request->user();

        $accounts = Account::where('user_id', $user->id)->get()->map(function ($acc) {
            return [
                'id' => $acc->id,
                'name' => $acc->name,
                'type' => $acc->type,
                'balance' => (float) $acc->balance,
                'icon' => $acc->icon ?? 'creditcard.fill',
                'color_hex' => $acc->color_hex ?? '#10B981',
            ];
        });

        $categories = Category::where('user_id', $user->id)
            ->orWhereNull('user_id')
            ->get()
            ->map(function ($cat) {
                return [
                    'id' => $cat->id,
                    'name' => $cat->name,
                    'type' => $cat->type,
                    'icon' => $cat->icon ?? 'tag.fill',
                    'color_hex' => $cat->color_hex ?? '#3B82F6',
                    'is_default' => (bool) $cat->is_default,
                ];
            });

        $transactions = Transaction::where('user_id', $user->id)
            ->orderBy('date', 'desc')
            ->get()
            ->map(function ($t) {
                return [
                    'id' => $t->id,
                    'account_id' => $t->account_id,
                    'account_name' => optional($t->account)->name,
                    'title' => $t->title,
                    'amount' => (float) $t->amount,
                    'type' => $t->type,
                    'category_name' => $t->category_name,
                    'date' => $t->date->format('Y-m-d H:i:s'),
                    'note' => $t->note,
                ];
            });

        $budgets = Budget::where('user_id', $user->id)->get()->map(function ($b) {
            return [
                'id' => $b->id,
                'category_name' => $b->category_name,
                'limit_amount' => (float) $b->limit_amount,
                'month' => (int) $b->month,
                'year' => (int) $b->year,
            ];
        });

        $goals = SavingsGoal::where('user_id', $user->id)->get()->map(function ($g) {
            return [
                'id' => $g->id,
                'title' => $g->title,
                'target_amount' => (float) $g->target_amount,
                'current_amount' => (float) $g->current_amount,
                'deadline' => $g->deadline->format('Y-m-d H:i:s'),
                'icon' => $g->icon ?? 'target',
            ];
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Data berhasil ditarik',
            'accounts' => $accounts,
            'categories' => $categories,
            'transactions' => $transactions,
            'budgets' => $budgets,
            'goals' => $goals,
        ]);
    }

    /**
     * POST /api/v1/sync
     * Menerima batch data baru / perubahan dari SwiftData lokal iPhone
     */
    public function push(Request $request)
    {
        $user = $request->user();

        $returnedAccounts = [];
        $returnedCategories = [];
        $returnedTransactions = [];
        $returnedBudgets = [];
        $returnedGoals = [];

        DB::transaction(function () use (
            $request,
            $user,
            &$returnedAccounts,
            &$returnedCategories,
            &$returnedTransactions,
            &$returnedBudgets,
            &$returnedGoals
        ) {
            // 1. Akun
            foreach ($request->input('accounts', []) as $accData) {
                $account = Account::updateOrCreate(
                    ['id' => $accData['id'] ?? null, 'user_id' => $user->id],
                    [
                        'name' => $accData['name'],
                        'type' => $accData['type'],
                        'balance' => $accData['balance'],
                        'icon' => $accData['icon'],
                        'color_hex' => $accData['color_hex'],
                    ]
                );
                $returnedAccounts[] = [
                    'id' => $account->id,
                    'local_uuid' => $accData['local_uuid'] ?? null,
                ];
            }

            // 2. Kategori Kustom
            foreach ($request->input('categories', []) as $catData) {
                if (!empty($catData['is_default'])) continue;
                $category = Category::updateOrCreate(
                    ['id' => $catData['id'] ?? null, 'user_id' => $user->id],
                    [
                        'name' => $catData['name'],
                        'type' => $catData['type'],
                        'icon' => $catData['icon'],
                        'color_hex' => $catData['color_hex'],
                        'is_default' => false,
                    ]
                );
                $returnedCategories[] = [
                    'id' => $category->id,
                    'local_uuid' => $catData['local_uuid'] ?? null,
                ];
            }

            // 3. Transaksi
            foreach ($request->input('transactions', []) as $transData) {
                $accountId = $transData['account_id'] ?? null;
                if (!$accountId && !empty($transData['account_name'])) {
                    $foundAcc = Account::where('user_id', $user->id)
                        ->where('name', $transData['account_name'])
                        ->first();
                    $accountId = $foundAcc ? $foundAcc->id : null;
                }

                $transaction = Transaction::updateOrCreate(
                    ['id' => $transData['id'] ?? null, 'user_id' => $user->id],
                    [
                        'account_id' => $accountId,
                        'title' => $transData['title'],
                        'amount' => $transData['amount'],
                        'type' => $transData['type'],
                        'category_name' => $transData['category_name'],
                        'date' => $transData['date'],
                        'note' => $transData['note'] ?? null,
                    ]
                );
                $returnedTransactions[] = [
                    'id' => $transaction->id,
                    'local_uuid' => $transData['local_uuid'] ?? null,
                ];
            }

            // 4. Anggaran
            foreach ($request->input('budgets', []) as $budgetData) {
                $budget = Budget::updateOrCreate(
                    [
                        'user_id' => $user->id,
                        'category_name' => $budgetData['category_name'],
                        'month' => $budgetData['month'],
                        'year' => $budgetData['year'],
                    ],
                    [
                        'limit_amount' => $budgetData['limit_amount'],
                    ]
                );
                $returnedBudgets[] = [
                    'id' => $budget->id,
                    'local_uuid' => $budgetData['local_uuid'] ?? null,
                ];
            }

            // 5. Target Tabungan
            foreach ($request->input('goals', []) as $goalData) {
                $goal = SavingsGoal::updateOrCreate(
                    ['id' => $goalData['id'] ?? null, 'user_id' => $user->id],
                    [
                        'title' => $goalData['title'],
                        'target_amount' => $goalData['target_amount'],
                        'current_amount' => $goalData['current_amount'],
                        'deadline' => $goalData['deadline'],
                        'icon' => $goalData['icon'],
                    ]
                );
                $returnedGoals[] = [
                    'id' => $goal->id,
                    'local_uuid' => $goalData['local_uuid'] ?? null,
                ];
            }
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Sinkronisasi batch berhasil disimpan',
            'accounts' => $returnedAccounts,
            'categories' => $returnedCategories,
            'transactions' => $returnedTransactions,
            'budgets' => $returnedBudgets,
            'goals' => $returnedGoals,
        ]);
    }
}
```

---

## 3. Skema Database MySQL (`database/migrations/...`)

Pastikan tabel di MySQL Laravel memiliki kolom yang sesuai dengan [SCHEMA.md](file:///Users/mac/KeySaku-iOS/docs/SCHEMA.md):

1. **`accounts`**: `id`, `user_id`, `name`, `type`, `balance` (decimal 15,2), `icon`, `color_hex`, `timestamps`.
2. **`categories`**: `id`, `user_id` (nullable), `name`, `type`, `icon`, `color_hex`, `is_default` (boolean), `timestamps`.
3. **`transactions`**: `id`, `user_id`, `account_id`, `title`, `amount` (decimal 15,2), `type`, `category_name`, `date` (datetime), `note` (text, nullable), `timestamps`.
4. **`budgets`**: `id`, `user_id`, `category_name`, `limit_amount` (decimal 15,2), `month` (tinyint), `year` (smallint), `timestamps`.
5. **`savings_goals`**: `id`, `user_id`, `title`, `target_amount` (decimal 15,2), `current_amount` (decimal 15,2), `deadline` (datetime), `icon`, `timestamps`.

---

## 4. Pengujian dengan `cURL`

### Uji Login & Dapatkan Token Sanctum:
```bash
curl -X POST https://keysaku.com/api/v1/login \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@keysaku.com", "password": "password123"}'
```

### Uji Pull Sync:
```bash
curl -X GET https://keysaku.com/api/v1/sync \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <TOKEN_DARI_LOGIN>"
```
