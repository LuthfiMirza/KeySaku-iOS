import Foundation
import SwiftData

/// Model SwiftData untuk Akun Keuangan (Kas, Bank, E-Wallet).
@Model
public final class Account {
    @Attribute(.unique) public var id: UUID
    public var remoteId: Int?
    public var name: String
    public var type: String // "Kas", "Bank", "E-Wallet"
    public var balance: Double
    public var icon: String
    public var colorHex: String
    public var isSynced: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    public var transactions: [Transaction]?
    
    public init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        name: String,
        type: String = "Kas",
        balance: Double = 0.0,
        icon: String = "banknote",
        colorHex: String = "#10B981",
        isSynced: Bool = false,
        transactions: [Transaction]? = []
    ) {
        self.id = id
        self.remoteId = remoteId
        self.name = name
        self.type = type
        self.balance = balance
        self.icon = icon
        self.colorHex = colorHex
        self.isSynced = isSynced
        self.transactions = transactions
    }
}
