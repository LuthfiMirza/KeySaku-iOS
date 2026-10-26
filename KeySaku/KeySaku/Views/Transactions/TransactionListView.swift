import SwiftUI
import SwiftData

/// Tampilan Riwayat Transaksi dengan Filter Bulan/Tahun, Kategori, Pencarian, dan Swipe-to-Delete
public struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var accounts: [Account]
    
    @State private var selectedDate: Date = Date()
    @State private var selectedCategoryFilter: String = "Semua"
    @State private var searchText: String = ""
    @State private var showingCreateSheet: Bool = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var transactionToDelete: Transaction? = nil
    @State private var showingDeleteAlert: Bool = false
    @State private var showingVoiceSheet: Bool = false
    
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
    
    /// Transaksi yang difilter berdasarkan Bulan, Tahun, Kategori, dan Teks Pencarian
    private var filteredTransactions: [Transaction] {
        allTransactions.filter { transaction in
            let transMonth = calendar.component(.month, from: transaction.date)
            let transYear = calendar.component(.year, from: transaction.date)
            
            guard transMonth == currentMonth && transYear == currentYear else {
                return false
            }
            
            if selectedCategoryFilter != "Semua" && transaction.categoryName != selectedCategoryFilter {
                return false
            }
            
            if !searchText.isEmpty {
                let matchTitle = transaction.title.localizedCaseInsensitiveContains(searchText)
                let matchNote = transaction.note.localizedCaseInsensitiveContains(searchText)
                let matchCategory = transaction.categoryName.localizedCaseInsensitiveContains(searchText)
                return matchTitle || matchNote || matchCategory
            }
            
            return true
        }
    }
    
    // Perhitungan Total Bulan Ini
    private var monthlyTransactions: [Transaction] {
        allTransactions.filter {
            calendar.component(.month, from: $0.date) == currentMonth &&
            calendar.component(.year, from: $0.date) == currentYear
        }
    }
    
    private var totalIncome: Double {
        monthlyTransactions
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpense: Double {
        monthlyTransactions
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var netBalance: Double {
        totalIncome - totalExpense
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Navigasi Bulan & Tahun
                monthSelectorHeader
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                
                // Ringkasan Keuangan Bulanan
                monthlySummaryCard
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                // Filter Chip Kategori (Horizontal Scroll)
                categoryFilterScrollView
                    .padding(.bottom, 8)
                
                // Daftar Transaksi
                if filteredTransactions.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Belum Ada Transaksi" : "Tidak Ditemukan",
                        systemImage: searchText.isEmpty ? "tray.fill" : "magnifyingglass",
                        description: Text(
                            searchText.isEmpty
                                ? "Belum ada transaksi di bulan \(CurrencyFormatter.formatMonthYear(selectedDate)). Tekan '+' untuk mencatat."
                                : "Tidak ada transaksi yang cocok dengan kata kunci '\(searchText)'."
                        )
                    )
                } else {
                    List {
                        ForEach(filteredTransactions) { transaction in
                            Button {
                                transactionToEdit = transaction
                            } label: {
                                transactionRow(for: transaction)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    transactionToDelete = transaction
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Hapus", systemImage: "trash.fill")
                                }
                                
                                Button {
                                    transactionToEdit = transaction
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Cari judul, kategori, atau catatan...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            showingVoiceSheet = true
                        } label: {
                            Image(systemName: "mic.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color(hex: "#10B981"))
                        }
                        
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color(hex: "#10B981"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingVoiceSheet) {
                VoiceTransactionSheet()
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateEditTransactionSheet()
            }
            .sheet(item: $transactionToEdit) { transaction in
                CreateEditTransactionSheet(transactionToEdit: transaction)
            }
            .confirmationDialog(
                "Hapus Transaksi?",
                isPresented: $showingDeleteAlert,
                titleVisibility: .visible,
                presenting: transactionToDelete
            ) { transaction in
                Button("Hapus & Kembalikan Saldo", role: .destructive) {
                    TransactionObserver.shared.deleteTransaction(transaction, in: modelContext)
                }
                Button("Batal", role: .cancel) {}
            } message: { transaction in
                Text("Menghapus transaksi '\(transaction.title)' senilai \(CurrencyFormatter.rupiah(transaction.amount)) akan otomatis mengembalikan saldo akun terkait.")
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
    
    private var monthlySummaryCard: some View {
        HStack(spacing: 12) {
            // Pemasukan
            VStack(alignment: .leading, spacing: 4) {
                Text("Pemasukan")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.rupiah(totalIncome))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: "#10B981"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(hex: "#10B981").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Pengeluaran
            VStack(alignment: .leading, spacing: 4) {
                Text("Pengeluaran")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.rupiah(totalExpense))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: "#EF4444"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(hex: "#EF4444").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Bersih / Sisa
            VStack(alignment: .leading, spacing: 4) {
                Text("Selisih")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.rupiah(netBalance))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(netBalance >= 0 ? .primary : Color(hex: "#EF4444"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var categoryFilterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "Semua",
                    isSelected: selectedCategoryFilter == "Semua"
                ) {
                    selectedCategoryFilter = "Semua"
                }
                
                let usedCategories = Array(Set(monthlyTransactions.map { $0.categoryName })).sorted()
                ForEach(usedCategories, id: \.self) { catName in
                    FilterChip(
                        title: catName,
                        isSelected: selectedCategoryFilter == catName
                    ) {
                        selectedCategoryFilter = catName
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func transactionRow(for transaction: Transaction) -> some View {
        let isIncome = transaction.type == "income"
        let categoryColor = categories.first(where: { $0.name == transaction.categoryName })?.colorHex ?? (isIncome ? "#10B981" : "#EF4444")
        let categoryIcon = categories.first(where: { $0.name == transaction.categoryName })?.icon ?? (isIncome ? "arrow.down.circle.fill" : "cart.fill")
        
        HStack(spacing: 12) {
            Image(systemName: categoryIcon)
                .font(.body)
                .frame(width: 40, height: 40)
                .background(Color(hex: categoryColor).opacity(0.18))
                .foregroundStyle(Color(hex: categoryColor))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Text(CurrencyFormatter.formatShortDate(transaction.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if let accName = transaction.account?.name {
                        Text(accName)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(isIncome ? "+" : "-")\(CurrencyFormatter.rupiah(transaction.amount))")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(isIncome ? Color(hex: "#10B981") : .primary)
                
                Text(transaction.categoryName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "#10B981") : Color(.tertiarySystemFill))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TransactionListView()
}
