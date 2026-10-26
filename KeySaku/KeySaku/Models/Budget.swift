import Foundation
import SwiftData

/// Model SwiftData untuk Anggaran Bulanan per Kategori.
@Model
public final class Budget {
    @Attribute(.unique) public var id: UUID
    public var remoteId: Int?
    public var categoryName: String
    public var limitAmount: Double
    public var month: Int // 1 - 12
    public var year: Int  // contoh: 2026
    public var isSynced: Bool
    
    public init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        categoryName: String,
        limitAmount: Double,
        month: Int,
        year: Int,
        isSynced: Bool = false
    ) {
        self.id = id
        self.remoteId = remoteId
        self.categoryName = categoryName
        self.limitAmount = limitAmount
        self.month = month
        self.year = year
        self.isSynced = isSynced
    }
}
