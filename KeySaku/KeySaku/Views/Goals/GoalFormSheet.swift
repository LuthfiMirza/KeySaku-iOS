import SwiftUI
import SwiftData

/// Lembar Form Tambah & Edit Target Tabungan (Savings Goals)
public struct GoalFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    private var goalToEdit: SavingsGoal?
    
    @State private var title: String = ""
    @State private var targetAmountText: String = ""
    @State private var currentAmountText: String = "0"
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var selectedIcon: String = "target"
    @State private var errorMessage: String? = nil
    
    private let availableIcons: [String] = [
        "target", "airplane", "car.fill", "house.fill", "laptopcomputer",
        "gift.fill", "heart.fill", "graduationcap.fill", "cart.fill",
        "cross.case.fill", "gamecontroller.fill", "bag.fill", "star.fill",
        "figure.walk", "umbrella.fill", "shield.fill"
    ]
    
    public init(goalToEdit: SavingsGoal? = nil) {
        self.goalToEdit = goalToEdit
        if let goal = goalToEdit {
            _title = State(initialValue: goal.title)
            _targetAmountText = State(initialValue: String(format: "%.0f", goal.targetAmount))
            _currentAmountText = State(initialValue: String(format: "%.0f", goal.currentAmount))
            _deadline = State(initialValue: goal.deadline)
            _selectedIcon = State(initialValue: goal.icon)
        }
    }
    
    private var isEditing: Bool {
        goalToEdit != nil
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section Info Utama
                Section("Detail Target Tabungan") {
                    TextField("Contoh: Dana Darurat, Liburan Bali", text: $title)
                    
                    HStack {
                        Text("Target Nominal")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Rp")
                                .foregroundStyle(.secondary)
                            TextField("0", text: $targetAmountText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .bold()
                        }
                    }
                    
                    HStack {
                        Text("Terkumpul Saat Ini")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Rp")
                                .foregroundStyle(.secondary)
                            TextField("0", text: $currentAmountText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    DatePicker(
                        "Batas Waktu",
                        selection: $deadline,
                        displayedComponents: .date
                    )
                }
                
                // Section Pilihan Ikon
                Section("Pilih Ikon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(hex: "#10B981") : Color(.tertiarySystemFill))
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Section Preview Ringkasan
                if let target = Double(targetAmountText.filter { $0.isNumber }), target > 0 {
                    let current = Double(currentAmountText.filter { $0.isNumber }) ?? 0.0
                    let ratio = min(max(current / target, 0.0), 1.0)
                    let percentage = Int(ratio * 100)
                    
                    Section("Pratinjau Capaian") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(CurrencyFormatter.rupiah(current)) / \(CurrencyFormatter.rupiah(target))")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(percentage)%")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(hex: "#10B981"))
                            }
                            
                            ProgressView(value: ratio)
                                .tint(Color(hex: "#10B981"))
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Target" : "Target Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Simpan" : "Tambah") {
                        saveGoal()
                    }
                    .bold()
                    .foregroundStyle(Color(hex: "#10B981"))
                }
            }
        }
    }
    
    private func saveGoal() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Nama target tabungan tidak boleh kosong."
            return
        }
        
        guard let targetAmount = Double(targetAmountText.filter { $0.isNumber }), targetAmount > 0 else {
            errorMessage = "Target nominal harus lebih besar dari Rp 0."
            return
        }
        
        let currentAmount = Double(currentAmountText.filter { $0.isNumber }) ?? 0.0
        
        if let existing = goalToEdit {
            existing.title = cleanTitle
            existing.targetAmount = targetAmount
            existing.currentAmount = currentAmount
            existing.deadline = deadline
            existing.icon = selectedIcon
            existing.isSynced = false
        } else {
            let newGoal = SavingsGoal(
                title: cleanTitle,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                deadline: deadline,
                icon: selectedIcon,
                isSynced: false
            )
            modelContext.insert(newGoal)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    GoalFormSheet()
}
