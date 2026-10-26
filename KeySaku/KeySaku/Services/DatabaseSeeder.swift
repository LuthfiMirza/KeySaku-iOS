import Foundation
import SwiftData

/// Layanan untuk menginisialisasi data awal (Kategori Tetap dan Akun Default) ke SwiftData
public final class DatabaseSeeder {
    
    /// Menjalankan seeding jika database lokal masih kosong
    @MainActor
    public static func seedIfNeeded(context: ModelContext) {
        seedCategories(context: context)
        seedAccounts(context: context)
        try? context.save()
    }
    
    @MainActor
    private static func seedCategories(context: ModelContext) {
        var fetchDescriptor = FetchDescriptor<Category>()
        fetchDescriptor.fetchLimit = 1
        
        guard let existing = try? context.fetch(fetchDescriptor), existing.isEmpty else {
            return
        }
        
        let defaultCategories: [(name: String, type: String, icon: String, colorHex: String)] = [
            // Kategori Pengeluaran (Expense)
            ("Makanan & Minuman", "expense", "fork.knife", "#EF4444"),
            ("Belanja Keluarga", "expense", "cart.fill", "#F59E0B"),
            ("Transportasi", "expense", "car.fill", "#3B82F6"),
            ("Tagihan & Utilitas", "expense", "bolt.fill", "#8B5CF6"),
            ("Pendidikan", "expense", "book.fill", "#EC4899"),
            ("Kesehatan", "expense", "cross.case.fill", "#10B981"),
            ("Hiburan", "expense", "gamecontroller.fill", "#6366F1"),
            ("Lainnya", "expense", "ellipsis.circle.fill", "#6B7280"),
            
            // Kategori Pemasukan (Income)
            ("Gaji", "income", "banknote.fill", "#10B981"),
            ("Bonus", "income", "gift.fill", "#F59E0B"),
            ("Hasil Usaha", "income", "building.2.fill", "#3B82F6"),
            ("Investasi", "income", "chart.line.uptrend.xyaxis", "#8B5CF6"),
            ("Lainnya (Pemasukan)", "income", "arrow.down.circle.fill", "#6B7280")
        ]
        
        for cat in defaultCategories {
            let category = Category(
                name: cat.name,
                type: cat.type,
                icon: cat.icon,
                colorHex: cat.colorHex,
                isDefault: true,
                isSynced: false
            )
            context.insert(category)
        }
    }
    
    @MainActor
    private static func seedAccounts(context: ModelContext) {
        var fetchDescriptor = FetchDescriptor<Account>()
        fetchDescriptor.fetchLimit = 1
        
        guard let existing = try? context.fetch(fetchDescriptor), existing.isEmpty else {
            return
        }
        
        let defaultAccounts: [(name: String, type: String, icon: String, colorHex: String)] = [
            ("Kas Tunai", "Kas", "banknote", "#10B981"),
            ("Bank Utama", "Bank", "building.columns", "#3B82F6"),
            ("E-Wallet", "E-Wallet", "wallet.pass", "#F59E0B")
        ]
        
        for acc in defaultAccounts {
            let account = Account(
                name: acc.name,
                type: acc.type,
                balance: 0.0,
                icon: acc.icon,
                colorHex: acc.colorHex,
                isSynced: false
            )
            context.insert(account)
        }
    }
}
