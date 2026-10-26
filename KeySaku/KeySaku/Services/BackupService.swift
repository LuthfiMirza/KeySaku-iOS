import Foundation
import SwiftData

/// Struktur data cadangan lengkap KeySaku (JSON Schema)
public struct LocalBackupContainer: Codable {
    public var appName: String = "KeySaku iOS"
    public var version: String = "1.0"
    public var exportedAt: String
    public var stats: BackupStats
    public var accounts: [AccountDTO]
    public var categories: [CategoryDTO]
    public var transactions: [TransactionDTO]
    public var budgets: [BudgetDTO]
    public var goals: [GoalDTO]
    
    public struct BackupStats: Codable {
        public var totalAccounts: Int
        public var totalCategories: Int
        public var totalTransactions: Int
        public var totalBudgets: Int
        public var totalGoals: Int
    }
}

/// Layanan Ekspor & Cadangan Data Lokal dalam format JSON
@MainActor
public final class BackupService {
    public static let shared = BackupService()
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    
    private init() {}
    
    /// Mengonversi seluruh data SwiftData menjadi berkas file JSON untuk dibagikan (ShareLink / Files)
    public func createBackupFile(context: ModelContext) -> URL? {
        let accounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let budgets = (try? context.fetch(FetchDescriptor<Budget>())) ?? []
        let goals = (try? context.fetch(FetchDescriptor<SavingsGoal>())) ?? []
        
        let container = LocalBackupContainer(
            exportedAt: dateFormatter.string(from: Date()),
            stats: LocalBackupContainer.BackupStats(
                totalAccounts: accounts.count,
                totalCategories: categories.count,
                totalTransactions: transactions.count,
                totalBudgets: budgets.count,
                totalGoals: goals.count
            ),
            accounts: accounts.map {
                AccountDTO(
                    id: $0.remoteId,
                    localUuid: $0.id.uuidString,
                    name: $0.name,
                    type: $0.type,
                    balance: $0.balance,
                    icon: $0.icon,
                    colorHex: $0.colorHex
                )
            },
            categories: categories.map {
                CategoryDTO(
                    id: $0.remoteId,
                    localUuid: $0.id.uuidString,
                    name: $0.name,
                    type: $0.type,
                    icon: $0.icon,
                    colorHex: $0.colorHex,
                    isDefault: $0.isDefault
                )
            },
            transactions: transactions.map {
                TransactionDTO(
                    id: $0.remoteId,
                    localUuid: $0.id.uuidString,
                    accountId: $0.account?.remoteId,
                    accountName: $0.account?.name,
                    title: $0.title,
                    amount: $0.amount,
                    type: $0.type,
                    categoryName: $0.categoryName,
                    date: dateFormatter.string(from: $0.date),
                    note: $0.note
                )
            },
            budgets: budgets.map {
                BudgetDTO(
                    id: $0.remoteId,
                    localUuid: $0.id.uuidString,
                    categoryName: $0.categoryName,
                    limitAmount: $0.limitAmount,
                    month: $0.month,
                    year: $0.year
                )
            },
            goals: goals.map {
                GoalDTO(
                    id: $0.remoteId,
                    localUuid: $0.id.uuidString,
                    title: $0.title,
                    targetAmount: $0.targetAmount,
                    currentAmount: $0.currentAmount,
                    deadline: dateFormatter.string(from: $0.deadline),
                    icon: $0.icon
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let jsonData = try? encoder.encode(container) else { return nil }
        
        let fileNameDateFormatter = DateFormatter()
        fileNameDateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = fileNameDateFormatter.string(from: Date())
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("KeySaku_Backup_\(dateString).json")
        
        do {
            try jsonData.write(to: tempFile)
            return tempFile
        } catch {
            return nil
        }
    }
}
