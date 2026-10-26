import SwiftUI
import SwiftData

/// Tampilan Dashboard Utama KeySaku dengan Organic Curved Header, Floating Balance Card,
/// Smart Carousel, Horizontal Category Strip, dan 2-Column Grid Akun Cepat.
public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int
    
    @Query private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var allBudgets: [Budget]
    @Query private var allGoals: [SavingsGoal]
    @Query(sort: \Category.name) private var allCategories: [Category]
    
    @State private var showingCreateTransactionSheet: Bool = false
    @State private var showingVoiceSheet: Bool = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var quickAddAccount: Account? = nil
    @State private var isBalanceHidden: Bool = false
    @State private var selectedCategoryFilter: String? = nil
    
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
    
    private var filteredRecentTransactions: [Transaction] {
        let list: [Transaction]
        if let cat = selectedCategoryFilter {
            list = allTransactions.filter { $0.categoryName == cat }
        } else {
            list = allTransactions
        }
        return Array(list.prefix(5))
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - 1. Organic Curved Hero Header + Floating Hero Card
                    heroHeaderSection
                    
                    VStack(spacing: 22) {
                        // MARK: - 2. Quick Actions Row
                        quickActionsRow
                            .padding(.horizontal)
                        
                        // MARK: - 3. Smart Promo Carousel
                        smartPromoSection
                            .padding(.horizontal)
                        
                        // MARK: - 4. Kategori Pilihan (Category Strip)
                        categoryStripSection
                        
                        // MARK: - 5. 2-Column Grid Akun Keuangan
                        accountsGridSection
                            .padding(.horizontal)
                        
                        // MARK: - 6. Transaksi Terbaru
                        recentTransactionsSection
                            .padding(.horizontal)
                            .padding(.bottom, 90)
                    }
                    .padding(.top, 14)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingCreateTransactionSheet) {
                CreateEditTransactionSheet(defaultAccount: quickAddAccount)
            }
            .sheet(isPresented: $showingVoiceSheet) {
                VoiceTransactionSheet()
            }
            .sheet(item: $transactionToEdit) { trans in
                CreateEditTransactionSheet(transactionToEdit: trans)
            }
        }
    }
    
    // MARK: - 1. Organic Curved Hero Header & Floating Card
    private var heroHeaderSection: some View {
        ZStack(alignment: .top) {
            // Background Curved Gradient
            CurvedHeaderShape(curveDepth: 36)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 240)
            
            VStack(spacing: 16) {
                // Top Bar: Profil Avatar, Sapaan & Tombol Voice
                HStack(alignment: .center, spacing: 12) {
                    // Avatar Pengguna
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Halo, Keluarga!")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        // Status Koneksi / Mode Offline
                        HStack(spacing: 5) {
                            Circle()
                                .fill(AuthService.shared.isOfflineMode ? Color.orange : Color.white)
                                .frame(width: 7, height: 7)
                            Text(AuthService.shared.isOfflineMode ? "Mode Offline" : "Tersinkronisasi")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    // Tombol Pintas Voice Assistant
                    Button {
                        HapticHelper.light()
                        showingVoiceSheet = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "#10B981"))
                            .frame(width: 40, height: 40)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // MARK: Floating Card Total Saldo Keluarga
                floatingBalanceCard
                    .padding(.horizontal, 16)
                    .offset(y: 4)
            }
        }
        .padding(.bottom, 2)
    }
    
    // MARK: - Floating Balance Card
    private var floatingBalanceCard: some View {
        VStack(spacing: 16) {
            // Baris Atas: Label & Tombol Mata Sensor
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "wallet.pass.fill")
                        .foregroundStyle(Color(hex: "#10B981"))
                        .font(.caption)
                    Text("Total Saldo Keluarga")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    HapticHelper.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isBalanceHidden.toggle()
                    }
                } label: {
                    Image(systemName: isBalanceHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
            }
            
            // Nominal Saldo Utama
            HStack(alignment: .firstTextBaseline) {
                if isBalanceHidden {
                    Text("Rp ••••••••")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                } else {
                    Text(CurrencyFormatter.rupiah(totalBalance))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
            }
            
            Divider()
            
            // Ringkasan Pemasukan & Pengeluaran Bulan Ini
            HStack(spacing: 10) {
                // Pemasukan
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.left")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "#10B981"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#10B981").opacity(0.14))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pemasukan")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(isBalanceHidden ? "Rp •••" : CurrencyFormatter.rupiah(monthlyIncome))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: "#10B981"))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Pengeluaran
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "#EF4444"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#EF4444").opacity(0.14))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pengeluaran")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(isBalanceHidden ? "Rp •••" : CurrencyFormatter.rupiah(monthlyExpense))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: "#EF4444"))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
    }
    
    // MARK: - 2. Quick Actions Row
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            // Tombol Catat Transaksi Baru
            Button {
                HapticHelper.light()
                quickAddAccount = nil
                showingCreateTransactionSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text("Catat Transaksi")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#10B981"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "#10B981").opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            
            // Tombol Suara Pintar
            Button {
                HapticHelper.light()
                showingVoiceSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.badge.mic")
                        .font(.headline)
                    Text("Suara Pintar")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(Color(hex: "#10B981"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 3. Smart Promo Carousel Section
    private var smartPromoSection: some View {
        let items = buildSmartPromoItems()
        return SmartPromoCarousel(items: items)
    }
    
    private func buildSmartPromoItems() -> [SmartPromoItem] {
        var items: [SmartPromoItem] = []
        
        // Item 1: Peringatan Anggaran (Jika ada yang lewat batas atau mendekati)
        let alertBudgets = monthlyBudgets.compactMap { b -> (name: String, spent: Double, limit: Double)? in
            let spent = monthlyTransactions
                .filter { $0.type == "expense" && $0.categoryName == b.categoryName }
                .reduce(0) { $0 + $1.amount }
            return (spent >= b.limitAmount * 0.8) ? (b.categoryName, spent, b.limitAmount) : nil
        }
        
        if let over = alertBudgets.first {
            let isOver = over.spent >= over.limit
            items.append(
                SmartPromoItem(
                    badge: isOver ? "Peringatan Batas" : "Mendekati Batas",
                    title: "\(over.name) \(isOver ? "Lewat Batas!" : "Hampir Habis")",
                    subtitle: "Terpakai \(CurrencyFormatter.rupiah(over.spent)) dari batas \(CurrencyFormatter.rupiah(over.limit)).",
                    buttonText: "Lihat Anggaran",
                    gradientColors: [Color(hex: "#EF4444"), Color(hex: "#DC2626")],
                    icon: "exclamationmark.triangle.fill",
                    action: { selectedTab = 2 }
                )
            )
        }
        
        // Item 2: Surplus Kas Sehat
        if monthlyIncome > monthlyExpense && monthlyIncome > 0 {
            let surplus = monthlyIncome - monthlyExpense
            items.append(
                SmartPromoItem(
                    badge: "Kondisi Kas Sehat",
                    title: "Surplus \(CurrencyFormatter.rupiah(surplus))",
                    subtitle: "Keluarga Anda berhasil menyisihkan kas bulan ini. Alokasikan ke target tabungan!",
                    buttonText: "Nabung Sekarang",
                    gradientColors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                    icon: "sparkles",
                    action: { selectedTab = 3 }
                )
            )
        }
        
        // Item 3: Progress Tabungan
        if let goal = allGoals.first {
            let pct = goal.targetAmount > 0 ? Int((goal.currentAmount / goal.targetAmount) * 100) : 0
            items.append(
                SmartPromoItem(
                    badge: "Target Tabungan",
                    title: goal.title,
                    subtitle: "Telah terkumpul \(CurrencyFormatter.rupiah(goal.currentAmount)) (\(pct)%) dari target.",
                    buttonText: "Tambah Tabungan",
                    gradientColors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
                    icon: "target",
                    action: { selectedTab = 3 }
                )
            )
        }
        
        // Item 4: Tips Finansial Ramah Keluarga
        items.append(
            SmartPromoItem(
                badge: "Tips KeySaku",
                title: "Catat Harian dengan Suara",
                subtitle: "Ucapkan 'Beli sayur 35 ribu pakai Tunai' untuk pencatatan instan tanpa ribet.",
                buttonText: "Coba Voice",
                gradientColors: [Color(hex: "#8B5CF6"), Color(hex: "#6D28D9")],
                icon: "mic.badge.plus",
                action: { showingVoiceSheet = true }
            )
        )
        
        return items
    }
    
    // MARK: - 4. Kategori Pilihan (Category Strip)
    private var categoryStripSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Kategori")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                NavigationLink {
                    ManageCategoriesView()
                } label: {
                    Text("Kelola Semua")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
            .padding(.horizontal)
            
            CategoryStripView(
                categories: allCategories,
                selectedCategoryName: $selectedCategoryFilter
            )
        }
    }
    
    // MARK: - 5. 2-Column Grid Akun Keuangan
    private var accountsGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Akun Saya")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                NavigationLink {
                    ManageAccountsView()
                } label: {
                    Text("Kelola Semua")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
            
            if accounts.isEmpty {
                Text("Belum ada akun keuangan terdaftar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 14
                ) {
                    ForEach(accounts) { account in
                        GridAccountCard(account: account) {
                            quickAddAccount = account
                            showingCreateTransactionSheet = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 6. 5 Transaksi Terbaru
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Transaksi Terbaru")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let cat = selectedCategoryFilter {
                        Text("Filter: \(cat)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color(hex: "#10B981"))
                    }
                }
                
                Spacer()
                
                Button {
                    selectedTab = 1 // Pindah ke Tab Transaksi
                } label: {
                    Text("Lihat Semua")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
            
            if filteredRecentTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text("Belum ada transaksi\(selectedCategoryFilter != nil ? " di kategori ini" : "").")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredRecentTransactions) { trans in
                        Button {
                            transactionToEdit = trans
                        } label: {
                            HStack(spacing: 12) {
                                let isIncome = trans.type == "income"
                                
                                // Ikon Panah Tipe
                                Image(systemName: isIncome ? "arrow.down.left" : "arrow.up.right")
                                    .font(.caption.bold())
                                    .frame(width: 36, height: 36)
                                    .background((isIncome ? Color(hex: "#10B981") : Color(hex: "#EF4444")).opacity(0.14))
                                    .foregroundStyle(isIncome ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                                    .clipShape(Circle())
                                
                                // Info Transaksi
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(trans.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 6) {
                                        Text(trans.categoryName)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.secondary)
                                        
                                        if let acc = trans.account {
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text(acc.name)
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(Color(hex: acc.colorHex))
                                        }
                                        
                                        Text("•")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(CurrencyFormatter.formatDate(trans.date))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Nominal Uang
                                Text((isIncome ? "+ " : "- ") + CurrencyFormatter.rupiah(trans.amount))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(isIncome ? Color(hex: "#10B981") : .primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
