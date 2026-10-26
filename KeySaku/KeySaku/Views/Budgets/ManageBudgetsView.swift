import SwiftUI
import SwiftData

/// Tampilan Manajemen Anggaran Bulanan dengan Perhitungan Real-Time & Indikator Status (Aman/Mendekati/Lewat)
public struct ManageBudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBudgets: [Budget]
    @Query private var allTransactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var selectedDate: Date = Date()
    @State private var showingAddSheet: Bool = false
    @State private var budgetToEdit: Budget? = nil
    @State private var budgetToDelete: Budget? = nil
    @State private var showingDeleteAlert: Bool = false
    
    // State untuk Salin Anggaran Bulan Lalu (Task 4.2)
    @State private var showingCopyAlert: Bool = false
    @State private var copyAlertMessage: String = ""
    
    public init() {}
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var currentMonth: Int {
        calendar.component(.month, from: selectedDate)
    }
    
    private var currentYear: Int {
        calendar.component(.year, from: selectedDate)
    }
    
    /// Anggaran pada bulan dan tahun yang sedang dipilih
    private var monthlyBudgets: [Budget] {
        allBudgets.filter { $0.month == currentMonth && $0.year == currentYear }
    }
    
    /// Transaksi pengeluaran pada bulan dan tahun yang sedang dipilih
    private var monthlyExpenses: [Transaction] {
        allTransactions.filter {
            $0.type == "expense" &&
            calendar.component(.month, from: $0.date) == currentMonth &&
            calendar.component(.year, from: $0.date) == currentYear
        }
    }
    
    /// Menghitung realisasi pengeluaran untuk kategori tertentu
    private func spentAmount(for categoryName: String) -> Double {
        monthlyExpenses
            .filter { $0.categoryName == categoryName }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Total seluruh batas anggaran bulan ini
    private var totalBudgetLimit: Double {
        monthlyBudgets.reduce(0) { $0 + $1.limitAmount }
    }
    
    /// Total seluruh realisasi pengeluaran pada kategori yang memiliki anggaran
    private var totalBudgetSpent: Double {
        monthlyBudgets.reduce(0) { $0 + spentAmount(for: $1.categoryName) }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Navigasi Bulan & Tahun
                monthSelectorHeader
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                
                // Ringkasan Total Anggaran Bulan Ini
                if !monthlyBudgets.isEmpty {
                    overallBudgetCard
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
                
                // Daftar Anggaran per Kategori
                if monthlyBudgets.isEmpty {
                    emptyBudgetsView
                } else {
                    List {
                        Section("Alokasi Anggaran Kategori") {
                            ForEach(monthlyBudgets) { budget in
                                Button {
                                    budgetToEdit = budget
                                } label: {
                                    budgetCardRow(for: budget)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        budgetToDelete = budget
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Hapus", systemImage: "trash.fill")
                                    }
                                    
                                    Button {
                                        budgetToEdit = budget
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Anggaran")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Tombol Salin Anggaran Bulan Lalu (Task 4.2)
                    Button {
                        copyPreviousMonthBudgets()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Salin Bulan Lalu")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color(hex: "#10B981"))
                    }
                }
                
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
                BudgetFormSheet(defaultMonth: currentMonth, defaultYear: currentYear)
            }
            .sheet(item: $budgetToEdit) { budget in
                BudgetFormSheet(budgetToEdit: budget)
            }
            .confirmationDialog(
                "Hapus Anggaran?",
                isPresented: $showingDeleteAlert,
                titleVisibility: .visible,
                presenting: budgetToDelete
            ) { budget in
                Button("Hapus Anggaran", role: .destructive) {
                    deleteBudget(budget)
                }
                Button("Batal", role: .cancel) {}
            } message: { budget in
                Text("Hapus batas anggaran untuk kategori '\(budget.categoryName)' di bulan \(CurrencyFormatter.monthName(month: budget.month)) \(String(budget.year))?")
            }
            .alert("Salin Anggaran Bulan Lalu", isPresented: $showingCopyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(copyAlertMessage)
            }
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
    
    private var overallBudgetCard: some View {
        let ratio = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit) : 0
        let percentage = Int(ratio * 100)
        let status = budgetStatus(percentage: percentage)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Anggaran Bulan Ini")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(CurrencyFormatter.rupiah(totalBudgetSpent)) / \(CurrencyFormatter.rupiah(totalBudgetLimit))")
                        .font(.headline.weight(.bold))
                }
                
                Spacer()
                
                // Status Badge Keseluruhan
                Text(status.title)
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.18))
                    .foregroundStyle(status.color)
                    .clipShape(Capsule())
            }
            
            // Progress Bar Visual
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(status.color)
                        .frame(width: min(proxy.size.width * CGFloat(min(ratio, 1.0)), proxy.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(percentage)% Terpakai")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(status.color)
                
                Spacer()
                
                let remaining = totalBudgetLimit - totalBudgetSpent
                if remaining >= 0 {
                    Text("Sisa: \(CurrencyFormatter.rupiah(remaining))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Lewat: \(CurrencyFormatter.rupiah(abs(remaining)))")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func budgetCardRow(for budget: Budget) -> some View {
        let spent = spentAmount(for: budget.categoryName)
        let ratio = budget.limitAmount > 0 ? (spent / budget.limitAmount) : 0
        let percentage = Int(ratio * 100)
        let status = budgetStatus(percentage: percentage)
        
        let catInfo = categories.first(where: { $0.name == budget.categoryName })
        let icon = catInfo?.icon ?? "tag.fill"
        let colorHex = catInfo?.colorHex ?? "#3B82F6"
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .frame(width: 36, height: 36)
                    .background(Color(hex: colorHex).opacity(0.18))
                    .foregroundStyle(Color(hex: colorHex))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.categoryName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("\(CurrencyFormatter.rupiah(spent)) dari \(CurrencyFormatter.rupiah(budget.limitAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status Badge per Kategori (Aman / Mendekati Batas / Lewat Batas)
                Text(status.title)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(status.color.opacity(0.15))
                    .foregroundStyle(status.color)
                    .clipShape(Capsule())
            }
            
            // Progress Bar Visual
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(status.color)
                        .frame(width: min(proxy.size.width * CGFloat(min(ratio, 1.0)), proxy.size.width), height: 6)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("\(percentage)%")
                    .font(.caption2.bold())
                    .foregroundStyle(status.color)
                
                Spacer()
                
                let remaining = budget.limitAmount - spent
                if remaining >= 0 {
                    Text("Sisa \(CurrencyFormatter.rupiah(remaining))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Lewat \(CurrencyFormatter.rupiah(abs(remaining)))")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var emptyBudgetsView: some View {
        ContentUnavailableView {
            Label("Belum Ada Anggaran", systemImage: "chart.pie.fill")
        } description: {
            Text("Atur batas pengeluaran bulanan per kategori agar keuangan keluarga tetap aman.")
        } actions: {
            VStack(spacing: 12) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Atur Anggaran Sekarang", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#10B981"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    copyPreviousMonthBudgets()
                } label: {
                    Label("Salin Anggaran Bulan Lalu", systemImage: "doc.on.doc.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Status Calculation (Sesuai AGENTS.md)
    // < 80%: Aman (Hijau)
    // 80% s/d < 100%: Mendekati Batas (Kuning / Oranye)
    // >= 100%: Lewat Batas (Merah)
    private func budgetStatus(percentage: Int) -> (title: String, color: Color) {
        if percentage < 80 {
            return ("Aman", Color(hex: "#10B981"))
        } else if percentage < 100 {
            return ("Mendekati Batas", Color(hex: "#F59E0B"))
        } else {
            return ("Lewat Batas", Color(hex: "#EF4444"))
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func deleteBudget(_ budget: Budget) {
        modelContext.delete(budget)
        try? modelContext.save()
        budgetToDelete = nil
    }
    
    // MARK: - Task 4.2: Salin Anggaran Bulan Lalu (1-Klik)
    private func copyPreviousMonthBudgets() {
        guard let prevDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) else { return }
        let prevMonth = calendar.component(.month, from: prevDate)
        let prevYear = calendar.component(.year, from: prevDate)
        
        let prevBudgets = allBudgets.filter { $0.month == prevMonth && $0.year == prevYear }
        
        guard !prevBudgets.isEmpty else {
            copyAlertMessage = "Tidak ada anggaran di bulan \(CurrencyFormatter.monthName(month: prevMonth)) \(String(prevYear)) untuk disalin."
            showingCopyAlert = true
            return
        }
        
        var copiedCount = 0
        for oldBudget in prevBudgets {
            // Cek apakah kategori ini sudah punya anggaran di bulan berjalan
            let alreadyExists = monthlyBudgets.contains { $0.categoryName == oldBudget.categoryName }
            if !alreadyExists {
                let newBudget = Budget(
                    categoryName: oldBudget.categoryName,
                    limitAmount: oldBudget.limitAmount,
                    month: currentMonth,
                    year: currentYear,
                    isSynced: false
                )
                modelContext.insert(newBudget)
                copiedCount += 1
            }
        }
        
        if copiedCount > 0 {
            try? modelContext.save()
            copyAlertMessage = "Berhasil menyalin \(copiedCount) anggaran dari bulan \(CurrencyFormatter.monthName(month: prevMonth)) \(String(prevYear))."
        } else {
            copyAlertMessage = "Seluruh anggaran dari bulan lalu sudah ada di bulan ini."
        }
        
        showingCopyAlert = true
    }
}

#Preview {
    ManageBudgetsView()
}
