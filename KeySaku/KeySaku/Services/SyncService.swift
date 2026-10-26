import Foundation
import SwiftData
import SwiftUI
import Observation

// MARK: - Codable DTOs untuk Kontrak REST API Laravel 12 (/api/v1/sync)

public struct AccountDTO: Codable {
    public var id: Int?
    public var localUuid: String?
    public var name: String
    public var type: String
    public var balance: Double
    public var icon: String
    public var colorHex: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case localUuid = "local_uuid"
        case name
        case type
        case balance
        case icon
        case colorHex = "color_hex"
    }
}

public struct CategoryDTO: Codable {
    public var id: Int?
    public var localUuid: String?
    public var name: String
    public var type: String
    public var icon: String
    public var colorHex: String
    public var isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case localUuid = "local_uuid"
        case name
        case type
        case icon
        case colorHex = "color_hex"
        case isDefault = "is_default"
    }
}

public struct TransactionDTO: Codable {
    public var id: Int?
    public var localUuid: String?
    public var accountId: Int?
    public var accountName: String?
    public var title: String
    public var amount: Double
    public var type: String
    public var categoryName: String
    public var date: String
    public var note: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case localUuid = "local_uuid"
        case accountId = "account_id"
        case accountName = "account_name"
        case title
        case amount
        case type
        case categoryName = "category_name"
        case date
        case note
    }
}

public struct BudgetDTO: Codable {
    public var id: Int?
    public var localUuid: String?
    public var categoryName: String
    public var limitAmount: Double
    public var month: Int
    public var year: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case localUuid = "local_uuid"
        case categoryName = "category_name"
        case limitAmount = "limit_amount"
        case month
        case year
    }
}

public struct GoalDTO: Codable {
    public var id: Int?
    public var localUuid: String?
    public var title: String
    public var targetAmount: Double
    public var currentAmount: Double
    public var deadline: String
    public var icon: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case localUuid = "local_uuid"
        case title
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case deadline
        case icon
    }
}

public struct SyncPayload: Codable {
    public var accounts: [AccountDTO]
    public var categories: [CategoryDTO]
    public var transactions: [TransactionDTO]
    public var budgets: [BudgetDTO]
    public var goals: [GoalDTO]
}

public struct SyncResponse: Codable {
    public var status: String?
    public var message: String?
    public var accounts: [AccountDTO]?
    public var categories: [CategoryDTO]?
    public var transactions: [TransactionDTO]?
    public var budgets: [BudgetDTO]?
    public var goals: [GoalDTO]?
}

// MARK: - SyncService Implementation

/// Layanan Sinkronisasi Dua Arah SwiftData (iPhone) <-> Laravel 12 REST API
@Observable
@MainActor
public final class SyncService {
    public static let shared = SyncService()
    
    public var isSyncing: Bool = false
    public var lastSyncDate: Date? {
        get {
            let timestamp = UserDefaults.standard.double(forKey: "keysaku_last_sync_timestamp")
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            if let val = newValue {
                UserDefaults.standard.set(val.timeIntervalSince1970, forKey: "keysaku_last_sync_timestamp")
            }
        }
    }
    public var lastSyncStatus: String = "Siap Sinkron"
    public var errorMessage: String? = nil
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    
    private init() {}
    
    /// Menjalankan sinkronisasi dua arah secara asinkron
    public func sync(context: ModelContext) async {
        // Jika dalam mode offline lokal atau belum login dengan token, lewati sync server
        guard !AuthService.shared.isOfflineMode,
              let token = KeychainHelper.shared.getToken(),
              !token.isEmpty else {
            lastSyncStatus = "Mode Offline Aktif"
            return
        }
        
        guard !isSyncing else { return }
        isSyncing = true
        errorMessage = nil
        lastSyncStatus = "Sedang Menyinkronkan..."
        
        do {
            // 1. Push Perubahan Lokal (isSynced == false) ke Server
            try await pushLocalChanges(context: context)
            
            // 2. Pull Data Terbaru dari Server ke SwiftData
            try await pullFromServer(context: context)
            
            lastSyncDate = Date()
            lastSyncStatus = "Tersinkronkan: \(CurrencyFormatter.formatDate(Date()))"
        } catch {
            errorMessage = error.localizedDescription
            lastSyncStatus = "Gagal Sinkron"
        }
        
        isSyncing = false
    }
    
    // MARK: - 1. Push Local Changes to Laravel API
    
    private func pushLocalChanges(context: ModelContext) async throws {
        // Ambil data yang belum tersinkron
        let accountDescriptor = FetchDescriptor<Account>(predicate: #Predicate { !$0.isSynced })
        let unsyncedAccounts = (try? context.fetch(accountDescriptor)) ?? []
        
        let categoryDescriptor = FetchDescriptor<Category>(predicate: #Predicate { !$0.isSynced })
        let unsyncedCategories = (try? context.fetch(categoryDescriptor)) ?? []
        
        let transactionDescriptor = FetchDescriptor<Transaction>(predicate: #Predicate { !$0.isSynced })
        let unsyncedTransactions = (try? context.fetch(transactionDescriptor)) ?? []
        
        let budgetDescriptor = FetchDescriptor<Budget>(predicate: #Predicate { !$0.isSynced })
        let unsyncedBudgets = (try? context.fetch(budgetDescriptor)) ?? []
        
        let goalDescriptor = FetchDescriptor<SavingsGoal>(predicate: #Predicate { !$0.isSynced })
        let unsyncedGoals = (try? context.fetch(goalDescriptor)) ?? []
        
        // Jika tidak ada data yang perlu di-push, lanjutkan ke pull
        if unsyncedAccounts.isEmpty && unsyncedCategories.isEmpty && unsyncedTransactions.isEmpty && unsyncedBudgets.isEmpty && unsyncedGoals.isEmpty {
            return
        }
        
        // Bentuk Payload
        let payload = SyncPayload(
            accounts: unsyncedAccounts.map {
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
            categories: unsyncedCategories.map {
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
            transactions: unsyncedTransactions.map {
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
            budgets: unsyncedBudgets.map {
                BudgetDTO(
                    id: $0.remoteId,
                    localUuid: $0.id.uuidString,
                    categoryName: $0.categoryName,
                    limitAmount: $0.limitAmount,
                    month: $0.month,
                    year: $0.year
                )
            },
            goals: unsyncedGoals.map {
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
        let bodyData = try encoder.encode(payload)
        
        guard let request = APIConfig.makeRequest(
            endpoint: APIConfig.syncEndpoint,
            method: "POST",
            body: bodyData,
            requiresAuth: true
        ) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Parse respon push untuk memperbarui remoteId dan tandai isSynced = true
        let syncResponse = try JSONDecoder().decode(SyncResponse.self, from: data)
        
        // Update Akun
        if let returnedAccounts = syncResponse.accounts {
            for dto in returnedAccounts {
                if let uuidStr = dto.localUuid, let uuid = UUID(uuidString: uuidStr),
                   let acc = unsyncedAccounts.first(where: { $0.id == uuid }) {
                    acc.remoteId = dto.id
                    acc.isSynced = true
                }
            }
        } else {
            unsyncedAccounts.forEach { $0.isSynced = true }
        }
        
        // Update Kategori
        if let returnedCategories = syncResponse.categories {
            for dto in returnedCategories {
                if let uuidStr = dto.localUuid, let uuid = UUID(uuidString: uuidStr),
                   let cat = unsyncedCategories.first(where: { $0.id == uuid }) {
                    cat.remoteId = dto.id
                    cat.isSynced = true
                }
            }
        } else {
            unsyncedCategories.forEach { $0.isSynced = true }
        }
        
        // Update Transaksi
        if let returnedTransactions = syncResponse.transactions {
            for dto in returnedTransactions {
                if let uuidStr = dto.localUuid, let uuid = UUID(uuidString: uuidStr),
                   let trans = unsyncedTransactions.first(where: { $0.id == uuid }) {
                    trans.remoteId = dto.id
                    trans.isSynced = true
                }
            }
        } else {
            unsyncedTransactions.forEach { $0.isSynced = true }
        }
        
        // Update Anggaran
        if let returnedBudgets = syncResponse.budgets {
            for dto in returnedBudgets {
                if let uuidStr = dto.localUuid, let uuid = UUID(uuidString: uuidStr),
                   let b = unsyncedBudgets.first(where: { $0.id == uuid }) {
                    b.remoteId = dto.id
                    b.isSynced = true
                }
            }
        } else {
            unsyncedBudgets.forEach { $0.isSynced = true }
        }
        
        // Update Goals
        if let returnedGoals = syncResponse.goals {
            for dto in returnedGoals {
                if let uuidStr = dto.localUuid, let uuid = UUID(uuidString: uuidStr),
                   let g = unsyncedGoals.first(where: { $0.id == uuid }) {
                    g.remoteId = dto.id
                    g.isSynced = true
                }
            }
        } else {
            unsyncedGoals.forEach { $0.isSynced = true }
        }
        
        try? context.save()
    }
    
    // MARK: - 2. Pull Server Data into SwiftData
    
    private func pullFromServer(context: ModelContext) async throws {
        guard let request = APIConfig.makeRequest(
            endpoint: APIConfig.syncEndpoint,
            method: "GET",
            requiresAuth: true
        ) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let syncResponse = try JSONDecoder().decode(SyncResponse.self, from: data)
        
        // 1. Akun
        let existingAccounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        if let serverAccounts = syncResponse.accounts {
            for dto in serverAccounts {
                if let existing = existingAccounts.first(where: { $0.remoteId == dto.id || $0.name == dto.name }) {
                    existing.remoteId = dto.id
                    existing.balance = dto.balance
                    existing.type = dto.type
                    existing.icon = dto.icon
                    existing.colorHex = dto.colorHex
                    existing.isSynced = true
                } else {
                    let newAcc = Account(
                        remoteId: dto.id,
                        name: dto.name,
                        type: dto.type,
                        balance: dto.balance,
                        icon: dto.icon,
                        colorHex: dto.colorHex,
                        isSynced: true
                    )
                    context.insert(newAcc)
                }
            }
        }
        
        // 2. Kategori
        let existingCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        if let serverCategories = syncResponse.categories {
            for dto in serverCategories {
                if let existing = existingCategories.first(where: { $0.remoteId == dto.id || ($0.name == dto.name && $0.type == dto.type) }) {
                    existing.remoteId = dto.id
                    existing.icon = dto.icon
                    existing.colorHex = dto.colorHex
                    existing.isSynced = true
                } else {
                    let newCat = Category(
                        remoteId: dto.id,
                        name: dto.name,
                        type: dto.type,
                        icon: dto.icon,
                        colorHex: dto.colorHex,
                        isDefault: dto.isDefault,
                        isSynced: true
                    )
                    context.insert(newCat)
                }
            }
        }
        
        // 3. Anggaran
        let existingBudgets = (try? context.fetch(FetchDescriptor<Budget>())) ?? []
        if let serverBudgets = syncResponse.budgets {
            for dto in serverBudgets {
                if let existing = existingBudgets.first(where: { $0.remoteId == dto.id || ($0.categoryName == dto.categoryName && $0.month == dto.month && $0.year == dto.year) }) {
                    existing.remoteId = dto.id
                    existing.limitAmount = dto.limitAmount
                    existing.isSynced = true
                } else {
                    let newB = Budget(
                        remoteId: dto.id,
                        categoryName: dto.categoryName,
                        limitAmount: dto.limitAmount,
                        month: dto.month,
                        year: dto.year,
                        isSynced: true
                    )
                    context.insert(newB)
                }
            }
        }
        
        // 4. Target Tabungan
        let existingGoals = (try? context.fetch(FetchDescriptor<SavingsGoal>())) ?? []
        if let serverGoals = syncResponse.goals {
            for dto in serverGoals {
                let deadlineDate = dateFormatter.date(from: dto.deadline) ?? Date()
                if let existing = existingGoals.first(where: { $0.remoteId == dto.id || $0.title == dto.title }) {
                    existing.remoteId = dto.id
                    existing.targetAmount = dto.targetAmount
                    existing.currentAmount = dto.currentAmount
                    existing.deadline = deadlineDate
                    existing.icon = dto.icon
                    existing.isSynced = true
                } else {
                    let newGoal = SavingsGoal(
                        remoteId: dto.id,
                        title: dto.title,
                        targetAmount: dto.targetAmount,
                        currentAmount: dto.currentAmount,
                        deadline: deadlineDate,
                        icon: dto.icon,
                        isSynced: true
                    )
                    context.insert(newGoal)
                }
            }
        }
        
        try? context.save()
    }
}
