import SwiftUI

/// Kartu Akun Keuangan gaya Grid 2-Kolom dengan tombol aksi cepat '+' (Sesuai Referensi Desain)
public struct GridAccountCard: View {
    public var account: Account
    public var onQuickAdd: () -> Void
    
    public init(account: Account, onQuickAdd: @escaping () -> Void) {
        self.account = account
        self.onQuickAdd = onQuickAdd
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Baris: Ikon & Tipe Akun
            HStack {
                Image(systemName: account.icon)
                    .font(.subheadline)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: account.colorHex).opacity(0.18))
                    .foregroundStyle(Color(hex: account.colorHex))
                    .clipShape(Circle())
                
                Spacer()
                
                Text(account.type)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemFill))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
            }
            
            // Nama Akun
            Text(account.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            // Saldo Akun
            Text(CurrencyFormatter.rupiah(account.balance))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            
            Spacer(minLength: 0)
            
            // Footer: Indikator & Tombol '+' Cepat
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 6, height: 6)
                    Text("Aktif")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Tombol Bulat '+' Hijau (Sesuai Referensi Desain)
                Button {
                    HapticHelper.light()
                    onQuickAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#10B981"))
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "#10B981").opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(height: 145)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
