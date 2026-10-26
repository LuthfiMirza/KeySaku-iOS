import Foundation
import SwiftData

/// Pengamat dan eksekutor mutasi transaksi yang menjamin pembaruan saldo akun (account.balance) secara atomik.
/// Wajib digunakan untuk seluruh operasi Create, Update, dan Delete transaksi.
@MainActor
public final class TransactionObserver {
    public static let shared = TransactionObserver()
    
    private init() {}
    
    /// Membuat transaksi baru dan secara atomik memperbarui saldo akun terkait
    @discardableResult
    public func createTransaction(
        title: String,
        amount: Double,
        type: String, // "income" atau "expense"
        categoryName: String,
        account: Account,
        date: Date = Date(),
        note: String = "",
        in context: ModelContext
    ) -> Transaction {
        // 1. Terapkan mutasi saldo pada akun
        if type == "income" {
            account.balance += amount
        } else {
            account.balance -= amount
        }
        account.isSynced = false
        
        // 2. Buat objek transaksi dan hubungkan ke akun
        let transaction = Transaction(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount,
            type: type,
            categoryName: categoryName,
            date: date,
            note: note.trimmingCharacters(in: .whitespaces),
            isSynced: false,
            account: account
        )
        
        context.insert(transaction)
        try? context.save()
        return transaction
    }
    
    /// Mengedit transaksi: mengembalikan efek saldo lama pada akun asal, lalu menerapkan saldo baru pada akun tujuan
    public func updateTransaction(
        _ transaction: Transaction,
        newTitle: String,
        newAmount: Double,
        newType: String,
        newCategoryName: String,
        newAccount: Account,
        newDate: Date,
        newNote: String,
        in context: ModelContext
    ) {
        // 1. Revert efek nominal & tipe lama pada akun asal
        if let oldAccount = transaction.account {
            if transaction.type == "income" {
                oldAccount.balance -= transaction.amount
            } else {
                oldAccount.balance += transaction.amount
            }
            oldAccount.isSynced = false
        }
        
        // 2. Terapkan efek nominal & tipe baru pada akun tujuan (bisa akun yang sama atau akun berbeda)
        if newType == "income" {
            newAccount.balance += newAmount
        } else {
            newAccount.balance -= newAmount
        }
        newAccount.isSynced = false
        
        // 3. Perbarui properti transaksi
        transaction.title = newTitle.trimmingCharacters(in: .whitespaces)
        transaction.amount = newAmount
        transaction.type = newType
        transaction.categoryName = newCategoryName
        transaction.account = newAccount
        transaction.date = newDate
        transaction.note = newNote.trimmingCharacters(in: .whitespaces)
        transaction.isSynced = false
        
        try? context.save()
    }
    
    /// Menghapus transaksi dan mengembalikan (revert) saldo akun terkait sebelum transaksi dihapus dari database
    public func deleteTransaction(
        _ transaction: Transaction,
        in context: ModelContext
    ) {
        // 1. Revert efek nominal & tipe pada akun terkait
        if let account = transaction.account {
            if transaction.type == "income" {
                account.balance -= transaction.amount
            } else {
                account.balance += transaction.amount
            }
            account.isSynced = false
        }
        
        // 2. Hapus entitas transaksi dari database
        context.delete(transaction)
        try? context.save()
    }
}
