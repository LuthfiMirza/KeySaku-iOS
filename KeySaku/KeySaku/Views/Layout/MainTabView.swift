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
            DashboardView(selectedTab: $selectedTab)
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(0)
            
            // Tab 2: Transaksi
            TransactionListView()
            .tabItem {
                Label("Transaksi", systemImage: "list.bullet.rectangle.portrait.fill")
            }
            .tag(1)
            
            // Tab 3: Anggaran
            ManageBudgetsView()
            .tabItem {
                Label("Anggaran", systemImage: "chart.pie.fill")
            }
            .tag(2)
            
            // Tab 4: Tabungan
            ManageGoalsView()
            .tabItem {
                Label("Tabungan", systemImage: "target")
            }
            .tag(3)
            
            // Tab 5: Laporan & Akun
            ReportsChartView()
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
