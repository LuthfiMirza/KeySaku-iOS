import SwiftUI
import SwiftData

/// Tampilan Dashboard Utama KeySaku dengan Ringkasan Total Saldo, Pergerakan Kas, Smart Insight & Quick Actions
public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int
    
    @Query private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var allBudgets: [Budget]
    @Query private var allGoals: [SavingsGoal]
    
    @State private var showingCreateTransactionSheet: Bool = false
    @State private var showingVoiceSheet: Bool = false
    @State private var showingManageAccounts: Bool = false
    @State private var transactionToEdit: Transaction? = nil
    
    public init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }
    
    private var calendar: Calendar { Calendar.current }
    
    private var currentMonth: Int {
        calendar.component(.month, from: Date())
    }
    
    private var currentYear: Int {
        calendar.component(.year, from: Date())
    }
    
    // MARK: - Perhitungan Finansial Real-Time
    
    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    private var monthlyTransactions: [Transaction] {
        allTransactions.filter {
            calendar.component(.month, from: $0.date) == currentMonth &&
            calendar.component(.year, from: $0.date) == currentYear
        }
    }
    
    private var monthlyIncome: Double {
        monthlyTransactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyExpense: Double {
        monthlyTransactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyBudgets: [Budget] {
        allBudgets.filter { $0.month == currentMonth && $0.year == currentYear }
    }
    
    private var totalBudgetLimit: Double {
        monthlyBudgets.reduce(0) { $0 + $1.limitAmount }
    }
    
    private var totalBudgetSpent: Double {
        monthlyBudgets.reduce(0) { total, budget in
            let spent = monthlyTransactions
                .filter { $0.type == "expense" && $0.categoryName == budget.categoryName }
                .reduce(0) { $0 + $1.amount }
            return total + spent
        }
    }
    
    private var recentTransactions: [Transaction] {
        Array(allTransactions.prefix(5))
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 1. Card Total Saldo Utama & Kas Bulanan
                    totalBalanceHeroCard
                        .padding(.horizontal)
                        .padding(.top, 4)
                    
                    // MARK: - 2. Quick Action Buttons (+ Transaksi & 🎤 Voice)
                    quickActionRow
                        .padding(.horizontal)
                    
                    // MARK: - 3. Smart Insight Otomatis Card
                    smartInsightCard
                        .padding(.horizontal)
                    
                    // MARK: - 4. Ringkasan Kesehatan Anggaran Bulanan
                    if !monthlyBudgets.isEmpty {
                        budgetHealthCard
                            .padding(.horizontal)
                    }
                    
                    // MARK: - 5. Daftar Akun Saya
                    accountsSection
                        .padding(.horizontal)
                    
                    // MARK: - 6. 5 Transaksi Terbaru
                    recentTransactionsSection
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("KeySaku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AuthService.shared.isOfflineMode ? Color.orange : Color(hex: "#10B981"))
                            .frame(width: 8, height: 8)
                        Text(AuthService.shared.isOfflineMode ? "Mode Offline" : "Tersambung")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingVoiceSheet = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.subheadline)
                            .padding(8)
                            .background(Color(hex: "#10B981").opacity(0.15))
                            .foregroundStyle(Color(hex: "#10B981"))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingCreateTransactionSheet) {
                CreateEditTransactionSheet()
            }
            .sheet(isPresented: $showingVoiceSheet) {
                VoiceTransactionSheet()
            }
            .sheet(item: $transactionToEdit) { trans in
                CreateEditTransactionSheet(transactionToEdit: trans)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var totalBalanceHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Saldo Keluarga")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                
                Text(CurrencyFormatter.rupiah(totalBalance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Divider()
                .overlay(.white.opacity(0.2))
            
            HStack(spacing: 12) {
                // Pemasukan Bulan Berjalan
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.left.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Pemasukan")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(CurrencyFormatter.rupiah(monthlyIncome))
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Pengeluaran Bulan Berjalan
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Pengeluaran")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(CurrencyFormatter.rupiah(monthlyExpense))
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "#10B981").opacity(0.25), radius: 10, y: 5)
    }
    
    private var quickActionRow: some View {
        HStack(spacing: 12) {
            // Tombol Catat Transaksi
            Button {
                showingCreateTransactionSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text("Catat Transaksi")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .foregroundStyle(Color(hex: "#10B981"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            // Tombol Suara Pintar
            Button {
                showingVoiceSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.headline)
                    Text("Input Suara")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#10B981"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - Smart Insight Otomatis
    private var smartInsightCard: some View {
        let insight = generateSmartInsight()
        
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundStyle(insight.color)
                .frame(width: 38, height: 38)
                .background(insight.color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(insight.color)
                    Spacer()
                    Text("Smart Insight")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private struct InsightData {
        var icon: String
        var color: Color
        var title: String
        var message: String
    }
    
    private func generateSmartInsight() -> InsightData {
        // Cek apakah ada kategori yang melebihi batas anggaran
        let overBudgetList = monthlyBudgets.compactMap { budget -> (name: String, limit: Double, spent: Double)? in
            let spent = monthlyTransactions
                .filter { $0.type == "expense" && $0.categoryName == budget.categoryName }
                .reduce(0) { $0 + $1.amount }
            return spent >= budget.limitAmount ? (budget.categoryName, budget.limitAmount, spent) : nil
        }
        
        if let firstOver = overBudgetList.first {
            return InsightData(
                icon: "exclamationmark.triangle.fill",
                color: Color(hex: "#EF4444"),
                title: "Peringatan Anggaran",
                message: "Kategori '\(firstOver.name)' telah melampaui batas anggaran bulan ini (\(CurrencyFormatter.rupiah(firstOver.spent)) dari batas \(CurrencyFormatter.rupiah(firstOver.limit)))."
            )
        }
        
        // Cek pengeluaran terbesar bulan ini
        let expenseTransactions = monthlyTransactions.filter { $0.type == "expense" }
        if !expenseTransactions.isEmpty {
            let grouped = Dictionary(grouping: expenseTransactions, by: { $0.categoryName })
            if let topCat = grouped.max(by: { $0.value.reduce(0) { $0 + $1.amount } < $1.value.reduce(0) { $0 + $1.amount } }) {
                let catTotal = topCat.value.reduce(0) { $0 + $1.amount }
                let pct = monthlyExpense > 0 ? Int((catTotal / monthlyExpense) * 100) : 0
                return InsightData(
                    icon: "chart.pie.fill",
                    color: Color(hex: "#3B82F6"),
                    title: "Pengeluaran Terbesar",
                    message: "Pengeluaran terbanyak ada di kategori '\(topCat.key)' sebesar \(CurrencyFormatter.rupiah(catTotal)) (\(pct)% dari total pengeluaran)."
                )
            }
        }
        
        // Cek surplus tabungan
        if monthlyIncome > monthlyExpense && monthlyIncome > 0 {
            let surplus = monthlyIncome - monthlyExpense
            return InsightData(
                icon: "sparkles",
                color: Color(hex: "#10B981"),
                title: "Kondisi Kas Sehat",
                message: "Bulan ini Anda memiliki surplus kas sebesar \(CurrencyFormatter.rupiah(surplus)). Yuk alokasikan ke Target Tabungan!"
            )
        }
        
        return InsightData(
            icon: "lightbulb.fill",
            color: Color(hex: "#F59E0B"),
            title: "Tips Keuangan",
            message: "Rutin mencatat setiap transaksi harian membantu menjaga kesehatan keuangan keluarga Anda."
        )
    }
    
    // MARK: - Ringkasan Anggaran Keseluruhan
    private var budgetHealthCard: some View {
        let ratio = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit) : 0
        let percentage = Int(ratio * 100)
        let statusColor: Color = percentage < 80 ? Color(hex: "#10B981") : (percentage < 100 ? Color(hex: "#F59E0B") : Color(hex: "#EF4444"))
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Anggaran Bulan Ini")
                    .font(.headline)
                Spacer()
                Button {
                    selectedTab = 2 // Pindah ke Tab Anggaran
                } label: {
                    Text("Kelola")
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
            
            HStack {
                Text("\(CurrencyFormatter.rupiah(totalBudgetSpent)) dari \(CurrencyFormatter.rupiah(totalBudgetLimit))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(percentage)% Terpakai")
                    .font(.caption.bold())
                    .foregroundStyle(statusColor)
            }
            
            ProgressView(value: min(ratio, 1.0))
                .tint(statusColor)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Akun Saya
    private var accountsSection: some View {
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
                HStack(spacing: 12) {
                    Image(systemName: account.icon)
                        .font(.body)
                        .frame(width: 38, height: 38)
                        .background(Color(hex: account.colorHex).opacity(0.18))
                        .foregroundStyle(Color(hex: account.colorHex))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
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
    
    // MARK: - 5 Transaksi Terbaru
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transaksi Terbaru")
                    .font(.headline)
                Spacer()
                Button {
                    selectedTab = 1 // Pindah ke Tab Transaksi
                } label: {
                    Text("Lihat Semua")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
            
            if recentTransactions.isEmpty {
                Text("Belum ada transaksi yang dicatat.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recentTransactions) { trans in
                    Button {
                        transactionToEdit = trans
                    } label: {
                        HStack(spacing: 12) {
                            let isIncome = trans.type == "income"
                            Image(systemName: isIncome ? "arrow.down.left" : "arrow.up.right")
                                .font(.caption.bold())
                                .frame(width: 34, height: 34)
                                .background((isIncome ? Color(hex: "#10B981") : Color.red).opacity(0.15))
                                .foregroundStyle(isIncome ? Color(hex: "#10B981") : .red)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trans.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                
                                Text("\(trans.categoryName) • \(CurrencyFormatter.formatDate(trans.date))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text((isIncome ? "+ " : "- ") + CurrencyFormatter.rupiah(trans.amount))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(isIncome ? Color(hex: "#10B981") : .primary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DashboardView()
}
