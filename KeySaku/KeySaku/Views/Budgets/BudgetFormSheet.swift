import SwiftUI
import SwiftData

/// Form Sheet untuk Menetapkan atau Mengedit Batas Anggaran Bulanan Kategori
public struct BudgetFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.name) private var categories: [Category]
    
    var budgetToEdit: Budget?
    var defaultMonth: Int
    var defaultYear: Int
    
    @State private var selectedCategoryName: String = ""
    @State private var limitAmountText: String = ""
    @State private var month: Int = 1
    @State private var year: Int = 2026
    @State private var errorMessage: String? = nil
    
    public init(
        budgetToEdit: Budget? = nil,
        defaultMonth: Int = Calendar.current.component(.month, from: Date()),
        defaultYear: Int = Calendar.current.component(.year, from: Date())
    ) {
        self.budgetToEdit = budgetToEdit
        self.defaultMonth = defaultMonth
        self.defaultYear = defaultYear
    }
    
    private var isEditing: Bool {
        budgetToEdit != nil
    }
    
    private var expenseCategories: [Category] {
        categories.filter { $0.type == "expense" }
    }
    
    private var parsedLimit: Double {
        let clean = limitAmountText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return Double(clean) ?? 0.0
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Kategori Pengeluaran") {
                    Picker("Pilih Kategori", selection: $selectedCategoryName) {
                        if expenseCategories.isEmpty {
                            Text("Tidak ada kategori pengeluaran").tag("")
                        } else {
                            ForEach(expenseCategories) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                }
                                .tag(cat.name)
                            }
                        }
                    }
                    .disabled(isEditing)
                }
                
                Section("Batas Anggaran Bulanan") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Batas Maksimal Pengeluaran (Rp)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        TextField("0", text: $limitAmountText)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .keyboardType(.numberPad)
                        
                        if parsedLimit > 0 {
                            Text(CurrencyFormatter.rupiah(parsedLimit))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Periode Anggaran") {
                    HStack {
                        Text("Bulan")
                        Spacer()
                        Text(CurrencyFormatter.monthName(month: month))
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Tahun")
                        Spacer()
                        Text("\(String(year))")
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Anggaran" : "Atur Anggaran Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveBudget()
                    }
                    .disabled(selectedCategoryName.isEmpty || parsedLimit <= 0)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                initForm()
            }
        }
    }
    
    private func initForm() {
        if let budget = budgetToEdit {
            selectedCategoryName = budget.categoryName
            limitAmountText = String(Int(budget.limitAmount))
            month = budget.month
            year = budget.year
        } else {
            month = defaultMonth
            year = defaultYear
            if let firstCat = expenseCategories.first {
                selectedCategoryName = firstCat.name
            }
        }
    }
    
    private func saveBudget() {
        if let budget = budgetToEdit {
            budget.limitAmount = parsedLimit
            budget.isSynced = false
        } else {
            // Cek apakah anggaran kategori ini sudah dibuat untuk bulan & tahun yang sama
            let targetCat = selectedCategoryName
            let targetMonth = month
            let targetYear = year
            var descriptor = FetchDescriptor<Budget>()
            descriptor.predicate = #Predicate<Budget> {
                $0.categoryName == targetCat && $0.month == targetMonth && $0.year == targetYear
            }
            
            if let existing = try? modelContext.fetch(descriptor), let first = existing.first {
                // Perbarui limit anggaran yang sudah ada
                first.limitAmount = parsedLimit
                first.isSynced = false
            } else {
                let newBudget = Budget(
                    categoryName: selectedCategoryName,
                    limitAmount: parsedLimit,
                    month: month,
                    year: year,
                    isSynced: false
                )
                modelContext.insert(newBudget)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    BudgetFormSheet()
}
