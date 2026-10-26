import SwiftUI
import SwiftData

/// Tampilan Manajemen Akun Keuangan (Kas, Bank, E-Wallet)
public struct ManageAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.name) private var accounts: [Account]
    
    @State private var showingAddSheet = false
    @State private var accountToEdit: Account? = nil
    @State private var accountToDelete: Account? = nil
    @State private var showingDeleteAlert = false
    
    public init() {}
    
    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    public var body: some View {
        List {
            // Header: Total Saldo Seluruh Akun
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Saldo Seluruh Akun")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    
                    Text(CurrencyFormatter.rupiah(totalBalance))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(accounts.count) akun aktif terdaftar")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowBackground(
                    LinearGradient(
                        colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            
            // Daftar Akun
            if accounts.isEmpty {
                ContentUnavailableView(
                    "Belum Ada Akun",
                    systemImage: "creditcard.trianglebadge.exclamationmark",
                    description: Text("Tekan tombol '+' di kanan atas untuk membuat akun keuangan pertama Anda.")
                )
            } else {
                Section("Daftar Akun Keuangan") {
                    ForEach(accounts) { account in
                        Button {
                            accountToEdit = account
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: account.icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(Color(hex: account.colorHex).opacity(0.18))
                                    .foregroundStyle(Color(hex: account.colorHex))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(account.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 6) {
                                        Text(account.type)
                                            .font(.caption2.weight(.medium))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: account.colorHex).opacity(0.15))
                                            .foregroundStyle(Color(hex: account.colorHex))
                                            .clipShape(Capsule())
                                        
                                        if !account.isSynced {
                                            Circle()
                                                .fill(.orange)
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Text(CurrencyFormatter.rupiah(account.balance))
                                    .font(.callout.weight(.bold))
                                    .foregroundStyle(account.balance < 0 ? .red : .primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                accountToDelete = account
                                showingDeleteAlert = true
                            } label: {
                                Label("Hapus", systemImage: "trash.fill")
                            }
                            
                            Button {
                                accountToEdit = account
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Kelola Akun")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AccountFormSheet()
        }
        .sheet(item: $accountToEdit) { account in
            AccountFormSheet(accountToEdit: account)
        }
        .confirmationDialog(
            "Hapus Akun Keuangan?",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible,
            presenting: accountToDelete
        ) { account in
            Button("Hapus Akun & Transaksi Terkait", role: .destructive) {
                deleteAccount(account)
            }
            Button("Batal", role: .cancel) {}
        } message: { account in
            Text("Peringatan: Menghapus akun '\(account.name)' akan menghapus seluruh data transaksi yang terkait dengan akun ini secara permanen.")
        }
    }
    
    private func deleteAccount(_ account: Account) {
        modelContext.delete(account)
        try? modelContext.save()
        accountToDelete = nil
    }
}

#Preview {
    NavigationStack {
        ManageAccountsView()
    }
}
