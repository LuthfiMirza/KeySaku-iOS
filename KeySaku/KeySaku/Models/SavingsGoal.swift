import Foundation
import SwiftData

/// Model SwiftData untuk Target Tabungan (Savings Goals).
@Model
public final class SavingsGoal {
    @Attribute(.unique) public var id: UUID
    public var remoteId: Int?
    public var title: String
    public var targetAmount: Double
    public var currentAmount: Double
    public var deadline: Date
    public var icon: String
    public var isSynced: Bool
    
    public init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        title: String,
        targetAmount: Double,
        currentAmount: Double = 0.0,
        deadline: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
        icon: String = "target",
        isSynced: Bool = false
    ) {
        self.id = id
        self.remoteId = remoteId
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.icon = icon
        self.isSynced = isSynced
    }
    
    /// Menambah kontribusi tabungan secara lokal ke progress bar
    /// (Sesuai AGENTS.md: HANYA menambah currentAmount dan TIDAK memotong saldo Account)
    public func addContribution(amount: Double) {
        guard amount > 0 else { return }
        self.currentAmount += amount
        self.isSynced = false
    }
    
    /// Persentase capaian tabungan (0.0 - 1.0)
    public var progressRatio: Double {
        guard targetAmount > 0 else { return 0.0 }
        return min(max(currentAmount / targetAmount, 0.0), 1.0)
    }
    
    /// Persentase capaian tabungan (0 - 100%)
    public var progressPercentage: Double {
        guard targetAmount > 0 else { return 0.0 }
        return (currentAmount / targetAmount) * 100.0
    }
    
    /// Sisa kekurangan target tabungan
    public var remainingAmount: Double {
        return max(targetAmount - currentAmount, 0.0)
    }
    
    /// Status apakah target tabungan sudah tercapai
    public var isCompleted: Bool {
        return currentAmount >= targetAmount && targetAmount > 0
    }
}
