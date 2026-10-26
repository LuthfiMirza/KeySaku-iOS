import Foundation
import SwiftData

/// Model SwiftData untuk Kategori Transaksi (Pemasukan & Pengeluaran).
@Model
public final class Category {
    @Attribute(.unique) public var id: UUID
    public var remoteId: Int?
    public var name: String
    public var type: String // "income" atau "expense"
    public var icon: String
    public var colorHex: String
    public var isDefault: Bool
    public var isSynced: Bool
    
    public init(
        id: UUID = UUID(),
        remoteId: Int? = nil,
        name: String,
        type: String,
        icon: String = "tag",
        colorHex: String = "#3B82F6",
        isDefault: Bool = false,
        isSynced: Bool = false
    ) {
        self.id = id
        self.remoteId = remoteId
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.isSynced = isSynced
    }
}
