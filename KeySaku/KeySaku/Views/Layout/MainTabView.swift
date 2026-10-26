import SwiftUI
import SwiftData

/// Navigasi Tab Utama aplikasi KeySaku
public struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            NavigationStack {
                DashboardPlaceholderView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(0)
            
            // Tab 2: Transaksi
            NavigationStack {
                TransactionPlaceholderView()
            }
            .tabItem {
                Label("Transaksi", systemImage: "list.bullet.rectangle.portrait.fill")
            }
            .tag(1)
            
            // Tab 3: Anggaran
            NavigationStack {
                BudgetPlaceholderView()
            }
            .tabItem {
                Label("Anggaran", systemImage: "chart.pie.fill")
            }
            .tag(2)
            
            // Tab 4: Tabungan
            NavigationStack {
                GoalPlaceholderView()
            }
            .tabItem {
                Label("Tabungan", systemImage: "target")
            }
            .tag(3)
            
            // Tab 5: Laporan & Akun
            NavigationStack {
                ReportPlaceholderView()
            }
            .tabItem {
                Label("Laporan", systemImage: "chart.bar.xaxis")
            }
            .tag(4)
        }
        .tint(Color(hex: "#10B981"))
        .onAppear {
            DatabaseSeeder.seedIfNeeded(context: modelContext)
        }
    }
}

// MARK: - Placeholder Views (akan digantikan di M2, M3, M4, M5)

struct DashboardPlaceholderView: View {
    @Binding var selectedTab: Int
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    
    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Card Total Saldo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Saldo Seluruh Akun")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyFormatter.rupiah(totalBalance))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Ringkasan Akun
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Akun Saya")
                            .font(.headline)
                        Spacer()
                        NavigationLink {
                            ManageAccountsView()
                        } label: {
                            Text("Kelola Semua")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(hex: "#10B981"))
                        }
                    }
                    
                    ForEach(accounts) { account in
                        HStack {
                            Image(systemName: account.icon)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: account.colorHex).opacity(0.15))
                                .foregroundStyle(Color(hex: account.colorHex))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(account.name)
                                    .font(.body.weight(.medium))
                                Text(account.type)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(CurrencyFormatter.rupiah(account.balance))
                                .font(.body.weight(.semibold))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle("KeySaku")
    }
}

struct TransactionPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Riwayat Transaksi",
            systemImage: "list.bullet.rectangle.portrait",
            description: Text("Daftar transaksi akan hadir lengkap di Milestone 3.")
        )
        .navigationTitle("Transaksi")
    }
}

struct BudgetPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Anggaran Bulanan",
            systemImage: "chart.pie",
            description: Text("Fitur alokasi anggaran bulanan akan hadir di Milestone 4.")
        )
        .navigationTitle("Anggaran")
    }
}

struct GoalPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Target Tabungan",
            systemImage: "target",
            description: Text("Pelacak capaian target tabungan akan hadir di Milestone 4.")
        )
        .navigationTitle("Tabungan")
    }
}

struct ReportPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Laporan Keuangan",
            systemImage: "chart.bar.xaxis",
            description: Text("Grafik Swift Charts dan laporan bulanan akan hadir di Milestone 5.")
        )
        .navigationTitle("Laporan")
    }
}

// MARK: - Color Hex Helper
extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 16, 185, 129)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MainTabView()
}
