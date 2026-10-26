import SwiftUI
import SwiftData
import Charts

/// Model data arus kas bulanan untuk Grafik Batang (BarMark)
public struct MonthlyCashFlow: Identifiable {
    public var id: String { monthLabel }
    public var monthLabel: String
    public var date: Date
    public var type: String // "Pemasukan" atau "Pengeluaran"
    public var amount: Double
}

/// Model data pengeluaran per kategori untuk Donut Chart (SectorMark)
public struct CategorySpending: Identifiable {
    public var id: String { categoryName }
    public var categoryName: String
    public var amount: Double
    public var percentage: Double
    public var colorHex: String
    public var icon: String
}

/// Tampilan Laporan Keuangan Visual dengan Swift Charts
public struct ReportsChartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTransactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var selectedDate: Date = Date()
    @State private var chartMode: ChartMode = .expense
    
    public enum ChartMode: String, CaseIterable, Identifiable {
        case expense = "Pengeluaran"
        case income = "Pemasukan"
        public var id: String { rawValue }
    }
    
    public init() {}
    
    private var calendar: Calendar { Calendar.current }
    
    private var currentMonth: Int {
        calendar.component(.month, from: selectedDate)
    }
    
    private var currentYear: Int {
        calendar.component(.year, from: selectedDate)
    }
    
    /// Transaksi pada bulan dan tahun terpilih
    private var monthlyTransactions: [Transaction] {
        allTransactions.filter {
            calendar.component(.month, from: $0.date) == currentMonth &&
            calendar.component(.year, from: $0.date) == currentYear
        }
    }
    
    /// Total Pemasukan Bulan Ini
    private var totalIncome: Double {
        monthlyTransactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }
    
    /// Total Pengeluaran Bulan Ini
    private var totalExpense: Double {
        monthlyTransactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }
    
    /// Selisih Bersih (Net Cash Flow)
    private var netSavings: Double {
        totalIncome - totalExpense
    }
    
    // MARK: - Data 6 Bulan Terakhir untuk BarMark
    private var sixMonthCashFlowData: [MonthlyCashFlow] {
        var items: [MonthlyCashFlow] = []
        
        // Ambil 6 bulan ke belakang dari selectedDate
        for i in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: selectedDate) else { continue }
            let m = calendar.component(.month, from: monthDate)
            let y = calendar.component(.year, from: monthDate)
            
            let monthLabel = CurrencyFormatter.monthName(month: m).prefix(3) + " " + String(y).suffix(2)
            
            let incomeTotal = allTransactions
                .filter { $0.type == "income" && calendar.component(.month, from: $0.date) == m && calendar.component(.year, from: $0.date) == y }
                .reduce(0) { $0 + $1.amount }
            
            let expenseTotal = allTransactions
                .filter { $0.type == "expense" && calendar.component(.month, from: $0.date) == m && calendar.component(.year, from: $0.date) == y }
                .reduce(0) { $0 + $1.amount }
            
            items.append(MonthlyCashFlow(monthLabel: String(monthLabel), date: monthDate, type: "Pemasukan", amount: incomeTotal))
            items.append(MonthlyCashFlow(monthLabel: String(monthLabel), date: monthDate, type: "Pengeluaran", amount: expenseTotal))
        }
        
        return items
    }
    
    // MARK: - Data Pengeluaran per Kategori Bulan Ini (Donut Chart)
    private var categoryBreakdown: [CategorySpending] {
        let targetType = chartMode == .expense ? "expense" : "income"
        let filtered = monthlyTransactions.filter { $0.type == targetType }
        let total = filtered.reduce(0) { $0 + $1.amount }
        
        guard total > 0 else { return [] }
        
        // Kelompokkan berdasarkan categoryName
        let grouped = Dictionary(grouping: filtered, by: { $0.categoryName })
        
        var result: [CategorySpending] = []
        for (catName, transList) in grouped {
            let catTotal = transList.reduce(0) { $0 + $1.amount }
            let percentage = (catTotal / total) * 100.0
            
            let catObj = categories.first(where: { $0.name == catName })
            let icon = catObj?.icon ?? "tag.fill"
            let colorHex = catObj?.colorHex ?? "#3B82F6"
            
            result.append(CategorySpending(
                categoryName: catName,
                amount: catTotal,
                percentage: percentage,
                colorHex: colorHex,
                icon: icon
            ))
        }
        
        return result.sorted { $0.amount > $1.amount }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Navigasi Periode Bulan
                    monthSelectorHeader
                        .padding(.horizontal)
                        .padding(.top, 4)
                    
                    // Card 1: Ringkasan Finansial Bulan Ini
                    financialSummaryCard
                        .padding(.horizontal)
                    
                    // Card 2: Grafik Batang Arus Kas 6 Bulan Terakhir (BarMark)
                    cashFlowBarChartCard
                        .padding(.horizontal)
                    
                    // Card 3: Donut Chart Kategori Bulan Ini (SectorMark)
                    categoryDonutChartCard
                        .padding(.horizontal)
                    
                    // Navigasi Cepat Kelola Master Data
                    quickManagementLinks
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Laporan Keuangan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    private var monthSelectorHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.bold))
                    .padding(8)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(CurrencyFormatter.formatMonthYear(selectedDate))
                .font(.headline.weight(.bold))
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.bold))
                    .padding(8)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
        }
    }
    
    private var financialSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Ringkasan Kas Bulan Ini")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                
                // Indikator Surplus / Defisit
                Text(netSavings >= 0 ? "Surplus" : "Defisit")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((netSavings >= 0 ? Color(hex: "#10B981") : Color.red).opacity(0.15))
                    .foregroundStyle(netSavings >= 0 ? Color(hex: "#10B981") : .red)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                // Pemasukan
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundStyle(Color(hex: "#10B981"))
                        Text("Pemasukan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(CurrencyFormatter.rupiah(totalIncome))
                        .font(.headline.bold())
                        .foregroundStyle(Color(hex: "#10B981"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 36)
                
                // Pengeluaran
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(Color.red)
                        Text("Pengeluaran")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(CurrencyFormatter.rupiah(totalExpense))
                        .font(.headline.bold())
                        .foregroundStyle(Color.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // Tabungan Bersih
            HStack {
                Text("Selisih Bersih (Cash Flow)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(CurrencyFormatter.rupiah(netSavings))
                    .font(.subheadline.bold())
                    .foregroundStyle(netSavings >= 0 ? Color(hex: "#10B981") : .red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var cashFlowBarChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tren Arus Kas (6 Bulan)")
                        .font(.headline)
                    Text("Perbandingan pemasukan vs pengeluaran")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Legend
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "#10B981")).frame(width: 8, height: 8)
                        Text("Masuk").font(.caption2).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "#EF4444")).frame(width: 8, height: 8)
                        Text("Keluar").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            
            // Swift Charts BarMark
            Chart(sixMonthCashFlowData) { item in
                BarMark(
                    x: .value("Bulan", item.monthLabel),
                    y: .value("Nominal", item.amount)
                )
                .foregroundStyle(item.type == "Pemasukan" ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                .position(by: .value("Tipe", item.type))
                .cornerRadius(4)
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    if let val = value.as(Double.self) {
                        AxisValueLabel {
                            Text(shortRupiah(val))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var categoryDonutChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distribusi per Kategori")
                        .font(.headline)
                    Text("Komposisi keuangan bulan \(CurrencyFormatter.monthName(month: currentMonth))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Switcher Pengeluaran vs Pemasukan
                Picker("Tipe", selection: $chartMode) {
                    ForEach(ChartMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }
            
            if categoryBreakdown.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Belum ada data \(chartMode.rawValue.lowercased()) di bulan ini.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Donut Chart (SectorMark)
                ZStack {
                    Chart(categoryBreakdown) { item in
                        SectorMark(
                            angle: .value("Nominal", item.amount),
                            innerRadius: .ratio(0.64),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(Color(hex: item.colorHex))
                    }
                    .frame(height: 200)
                    
                    // Center Info Donut
                    VStack(spacing: 2) {
                        Text("Total \(chartMode.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        let total = chartMode == .expense ? totalExpense : totalIncome
                        Text(shortRupiah(total))
                            .font(.headline.bold())
                    }
                }
                
                Divider()
                
                // Rincian Kategori Tabel / Baris
                VStack(spacing: 10) {
                    ForEach(categoryBreakdown) { cat in
                        HStack(spacing: 12) {
                            Image(systemName: cat.icon)
                                .font(.subheadline)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: cat.colorHex).opacity(0.18))
                                .foregroundStyle(Color(hex: cat.colorHex))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(cat.categoryName)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(CurrencyFormatter.rupiah(cat.amount))
                                        .font(.subheadline.weight(.bold))
                                }
                                
                                HStack {
                                    ProgressView(value: cat.percentage / 100.0)
                                        .tint(Color(hex: cat.colorHex))
                                    Text("\(String(format: "%.1f", cat.percentage))%")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var quickManagementLinks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pengaturan Data")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            NavigationLink {
                ManageAccountsView()
            } label: {
                HStack {
                    Label("Kelola Akun & Dompet", systemImage: "creditcard.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            NavigationLink {
                ManageCategoriesView()
            } label: {
                HStack {
                    Label("Kelola Kategori Transaksi", systemImage: "tag.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func shortRupiah(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fft", value / 1_000_000).replacingOccurrences(of: "ft", with: "jt")
        } else if value >= 1_000 {
            return String(format: "%.0frb", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

#Preview {
    ReportsChartView()
}
