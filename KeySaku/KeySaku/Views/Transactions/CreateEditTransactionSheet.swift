import SwiftUI
import SwiftData

/// Form Sheet untuk Mencatat Transaksi Baru atau Mengedit Transaksi yang Ada
public struct CreateEditTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]
    
    var transactionToEdit: Transaction?
    
    @State private var type: String = "expense" // "expense" atau "income"
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var selectedCategoryName: String = ""
    @State private var selectedAccount: Account? = nil
    @State private var date: Date = Date()
    @State private var note: String = ""
    
    public init(transactionToEdit: Transaction? = nil) {
        self.transactionToEdit = transactionToEdit
    }
    
    private var isEditing: Bool {
        transactionToEdit != nil
    }
    
    private var availableCategories: [Category] {
        categories.filter { $0.type == type }
    }
    
    private var parsedAmount: Double {
        let clean = amountText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return Double(clean) ?? 0.0
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedAmount > 0 &&
        selectedAccount != nil &&
        !selectedCategoryName.isEmpty
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Tipe Transaksi: Pengeluaran vs Pemasukan
                Section {
                    Picker("Jenis Transaksi", selection: $type) {
                        Text("Pengeluaran").tag("expense")
                        Text("Pemasukan").tag("income")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, newType in
                        // Sesuaikan kategori default dengan tipe baru
                        if let firstCat = categories.first(where: { $0.type == newType }) {
                            selectedCategoryName = firstCat.name
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                
                // Nominal Input Besar
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nominal Uang")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .firstTextBaseline) {
                            Text("Rp")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(type == "income" ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                            
                            TextField("0", text: $amountText)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                                .foregroundStyle(type == "income" ? Color(hex: "#10B981") : .primary)
                        }
                        
                        if parsedAmount > 0 {
                            Text(CurrencyFormatter.rupiah(parsedAmount))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Detail Transaksi
                Section("Detail Transaksi") {
                    TextField("Deskripsi / Judul (contoh: Makan Siang)", text: $title)
                    
                    // Pilihan Kategori
                    Picker("Kategori", selection: $selectedCategoryName) {
                        if availableCategories.isEmpty {
                            Text("Belum ada kategori").tag("")
                        } else {
                            ForEach(availableCategories) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                }
                                .tag(cat.name)
                            }
                        }
                    }
                    
                    // Pilihan Akun
                    Picker("Akun Keuangan", selection: $selectedAccount) {
                        if accounts.isEmpty {
                            Text("Belum ada akun").tag(nil as Account?)
                        } else {
                            ForEach(accounts) { acc in
                                HStack {
                                    Image(systemName: acc.icon)
                                    Text("\(acc.name) (\(CurrencyFormatter.rupiah(acc.balance)))")
                                }
                                .tag(acc as Account?)
                            }
                        }
                    }
                    
                    DatePicker("Tanggal", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "id_ID"))
                }
                
                // Catatan Tambahan
                Section("Catatan Tambahan (Opsional)") {
                    TextField("Tulis catatan atau rincian transaksi...", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Transaksi" : "Catat Transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                initFormState()
            }
        }
    }
    
    private func initFormState() {
        if let transaction = transactionToEdit {
            type = transaction.type
            title = transaction.title
            amountText = String(Int(transaction.amount))
            selectedCategoryName = transaction.categoryName
            selectedAccount = transaction.account
            date = transaction.date
            note = transaction.note
        } else {
            // Set default account jika belum terpilih
            if selectedAccount == nil {
                selectedAccount = accounts.first
            }
            // Set default category
            if selectedCategoryName.isEmpty {
                selectedCategoryName = availableCategories.first?.name ?? "Makanan & Minuman"
            }
        }
    }
    
    private func saveTransaction() {
        guard let account = selectedAccount else { return }
        
        if let transaction = transactionToEdit {
            TransactionObserver.shared.updateTransaction(
                transaction,
                newTitle: title,
                newAmount: parsedAmount,
                newType: type,
                newCategoryName: selectedCategoryName,
                newAccount: account,
                newDate: date,
                newNote: note,
                in: modelContext
            )
        } else {
            TransactionObserver.shared.createTransaction(
                title: title,
                amount: parsedAmount,
                type: type,
                categoryName: selectedCategoryName,
                account: account,
                date: date,
                note: note,
                in: modelContext
            )
        }
        
        dismiss()
    }
}

#Preview {
    CreateEditTransactionSheet()
}
