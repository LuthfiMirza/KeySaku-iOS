import Foundation
import SwiftData

/// Model SwiftData untuk Transaksi Keuangan (Pemasukan & Pengeluaran).
@Model
public final class Transaction {
    @Attribute(.unique) public var id: UUID
    public var remoteId: Int?
    public var title: String
    public var amount: Double
    public var type: String // "income" atau "expense"
    public var categoryName: String
    public var date: Date
    public var note: String
    public var isSynced: Bool
    
    public var account: Account?
    
    public init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        title: String,
        amount: Double,
        type: String,
        categoryName: String,
        date: Date = Date(),
        note: String = "",
        isSynced: Bool = false,
        account: Account? = nil
    ) {
        self.id = id
        self.remoteId = remoteId
        self.title = title
        self.amount = amount
        self.type = type
        self.categoryName = categoryName
        self.date = date
        self.note = note
        self.isSynced = isSynced
        self.account = account
    }
}
