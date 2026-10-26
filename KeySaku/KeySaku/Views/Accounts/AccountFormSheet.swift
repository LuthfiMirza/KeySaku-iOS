import SwiftUI
import SwiftData

/// Form Sheet untuk Menambah dan Mengedit Akun Keuangan (Kas, Bank, E-Wallet)
public struct AccountFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var accountToEdit: Account?
    
    @State private var name: String = ""
    @State private var selectedType: String = "Kas"
    @State private var balanceText: String = ""
    @State private var selectedIcon: String = "banknote"
    @State private var selectedColorHex: String = "#10B981"
    
    private let accountTypes = ["Kas", "Bank", "E-Wallet"]
    
    private let iconPresets = [
        "banknote",
        "building.columns",
        "wallet.pass",
        "creditcard",
        "dollarsign.circle",
        "bag.fill",
        "chart.line.uptrend.xyaxis",
        "safe"
    ]
    
    private let colorPresets = [
        "#10B981", // Emerald
        "#3B82F6", // Blue
        "#F59E0B", // Amber
        "#8B5CF6", // Purple
        "#EF4444", // Red
        "#EC4899", // Pink
        "#6366F1", // Indigo
        "#14B8A6"  // Teal
    ]
    
    public init(accountToEdit: Account? = nil) {
        self.accountToEdit = accountToEdit
    }
    
    private var isEditing: Bool {
        accountToEdit != nil
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section Info Dasar
                Section("Informasi Akun") {
                    TextField("Nama Akun (contoh: BCA, Kas Tunai)", text: $name)
                    
                    Picker("Tipe Akun", selection: $selectedType) {
                        ForEach(accountTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Saldo Akun (Rp)")
                        Spacer()
                        TextField("0", text: $balanceText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Section Ikon
                Section("Pilih Ikon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(iconPresets, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 52, height: 52)
                                    .background(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color(.tertiarySystemFill))
                                    .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedIcon == icon ? Color(hex: selectedColorHex) : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // Section Warna
                Section("Pilih Warna Kartu") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(colorPresets, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                            .shadow(radius: 2)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .opacity(selectedColorHex == hex ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // Pratinjau Tampilan Akun
                Section("Pratinjau Kartu") {
                    HStack(spacing: 14) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .frame(width: 48, height: 48)
                            .background(Color(hex: selectedColorHex).opacity(0.18))
                            .foregroundStyle(Color(hex: selectedColorHex))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "Nama Akun" : name)
                                .font(.headline)
                            Text(selectedType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        let parsedBalance = Double(balanceText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0.0
                        Text(CurrencyFormatter.rupiah(parsedBalance))
                            .font(.headline.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Akun" : "Tambah Akun Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveAccount()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let account = accountToEdit {
                    name = account.name
                    selectedType = account.type
                    balanceText = String(Int(account.balance))
                    selectedIcon = account.icon
                    selectedColorHex = account.colorHex
                }
            }
        }
    }
    
    private func saveAccount() {
        let cleanBalanceString = balanceText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let balance = Double(cleanBalanceString) ?? 0.0
        
        if let account = accountToEdit {
            account.name = name.trimmingCharacters(in: .whitespaces)
            account.type = selectedType
            account.balance = balance
            account.icon = selectedIcon
            account.colorHex = selectedColorHex
            account.isSynced = false
        } else {
            let newAccount = Account(
                name: name.trimmingCharacters(in: .whitespaces),
                type: selectedType,
                balance: balance,
                icon: selectedIcon,
                colorHex: selectedColorHex,
                isSynced: false
            )
            modelContext.insert(newAccount)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AccountFormSheet()
}
