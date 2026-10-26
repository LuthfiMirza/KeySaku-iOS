import SwiftUI
import SwiftData

/// Form Sheet untuk Menambah dan Mengedit Kategori Kustom
public struct CategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var categoryToEdit: Category?
    var initialType: String = "expense"
    
    @State private var name: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColorHex: String = "#3B82F6"
    
    private let iconPresets = [
        "fork.knife",
        "cart.fill",
        "car.fill",
        "bolt.fill",
        "book.fill",
        "cross.case.fill",
        "gamecontroller.fill",
        "banknote.fill",
        "gift.fill",
        "bag.fill",
        "house.fill",
        "airplane",
        "tshirt.fill",
        "film.fill",
        "fuelpump.fill",
        "graduationcap.fill",
        "heart.fill",
        "star.fill",
        "tag.fill",
        "ellipsis.circle.fill"
    ]
    
    private let colorPresets = [
        "#EF4444", // Merah
        "#F59E0B", // Oranye / Amber
        "#10B981", // Hijau
        "#3B82F6", // Biru
        "#6366F1", // Indigo
        "#8B5CF6", // Ungu
        "#EC4899", // Pink
        "#6B7280"  // Abu-abu
    ]
    
    public init(categoryToEdit: Category? = nil, initialType: String = "expense") {
        self.categoryToEdit = categoryToEdit
        self.initialType = initialType
    }
    
    private var isEditing: Bool {
        categoryToEdit != nil
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Informasi Kategori") {
                    TextField("Nama Kategori (contoh: Belanja Bulanan)", text: $name)
                    
                    Picker("Jenis Transaksi", selection: $selectedType) {
                        Text("Pengeluaran").tag("expense")
                        Text("Pemasukan").tag("income")
                    }
                    .pickerStyle(.segmented)
                    .disabled(isEditing) // Jangan ubah jenis kategori jika sedang edit
                }
                
                Section("Pilih Ikon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(iconPresets, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 48, height: 48)
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
                
                Section("Pilih Warna") {
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
                
                Section("Pratinjau") {
                    HStack(spacing: 14) {
                        Image(systemName: selectedIcon)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: selectedColorHex).opacity(0.18))
                            .foregroundStyle(Color(hex: selectedColorHex))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "Nama Kategori" : name)
                                .font(.headline)
                            Text(selectedType == "expense" ? "Pengeluaran" : "Pemasukan")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Kategori" : "Kategori Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let cat = categoryToEdit {
                    name = cat.name
                    selectedType = cat.type
                    selectedIcon = cat.icon
                    selectedColorHex = cat.colorHex
                } else {
                    selectedType = initialType
                    selectedColorHex = initialType == "income" ? "#10B981" : "#EF4444"
                }
            }
        }
    }
    
    private func saveCategory() {
        if let cat = categoryToEdit {
            cat.name = name.trimmingCharacters(in: .whitespaces)
            cat.icon = selectedIcon
            cat.colorHex = selectedColorHex
            cat.isSynced = false
        } else {
            let newCat = Category(
                name: name.trimmingCharacters(in: .whitespaces),
                type: selectedType,
                icon: selectedIcon,
                colorHex: selectedColorHex,
                isDefault: false,
                isSynced: false
            )
            modelContext.insert(newCat)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CategoryFormSheet()
}
