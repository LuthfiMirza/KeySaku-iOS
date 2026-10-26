import SwiftUI
import SwiftData

/// Tampilan Manajemen Kategori (Kategori Tetap Bawaan & Kategori Kustom)
public struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var allCategories: [Category]
    
    @State private var selectedTabType: String = "expense"
    @State private var showingAddSheet: Bool = false
    @State private var categoryToEdit: Category? = nil
    @State private var categoryToDelete: Category? = nil
    @State private var showingDeleteAlert: Bool = false
    
    public init() {}
    
    private var filteredCategories: [Category] {
        allCategories.filter { $0.type == selectedTabType }
    }
    
    private var defaultCategories: [Category] {
        filteredCategories.filter { $0.isDefault }
    }
    
    private var customCategories: [Category] {
        filteredCategories.filter { !$0.isDefault }
    }
    
    public var body: some View {
        List {
            // Segmented Picker Pengeluaran / Pemasukan
            Section {
                Picker("Jenis Kategori", selection: $selectedTabType) {
                    Text("Pengeluaran").tag("expense")
                    Text("Pemasukan").tag("income")
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
            
            // Kategori Kustom Pengguna
            Section {
                if customCategories.isEmpty {
                    Text("Belum ada kategori kustom. Tekan '+' untuk membuat kategori sendiri.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(customCategories) { cat in
                        Button {
                            categoryToEdit = cat
                        } label: {
                            categoryRow(for: cat, isCustom: true)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                categoryToDelete = cat
                                showingDeleteAlert = true
                            } label: {
                                Label("Hapus", systemImage: "trash.fill")
                            }
                            
                            Button {
                                categoryToEdit = cat
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Kategori Kustom Anda")
                    Spacer()
                    Text("\(customCategories.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            
            // Kategori Bawaan Sistem
            Section {
                ForEach(defaultCategories) { cat in
                    categoryRow(for: cat, isCustom: false)
                }
            } header: {
                HStack {
                    Text("Kategori Tetap (Bawaan Sistem)")
                    Spacer()
                    Text("\(defaultCategories.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Kategori bawaan sistem tidak dapat dihapus untuk memastikan integritas sinkronisasi laporan.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Kategori Transaksi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
            CategoryFormSheet(initialType: selectedTabType)
        }
        .sheet(item: $categoryToEdit) { cat in
            CategoryFormSheet(categoryToEdit: cat)
        }
        .confirmationDialog(
            "Hapus Kategori Kustom?",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible,
            presenting: categoryToDelete
        ) { cat in
            Button("Hapus Kategori", role: .destructive) {
                deleteCategory(cat)
            }
            Button("Batal", role: .cancel) {}
        } message: { cat in
            Text("Apakah Anda yakin ingin menghapus kategori '\(cat.name)'?")
        }
    }
    
    @ViewBuilder
    private func categoryRow(for cat: Category, isCustom: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: cat.icon)
                .font(.body)
                .frame(width: 36, height: 36)
                .background(Color(hex: cat.colorHex).opacity(0.18))
                .foregroundStyle(Color(hex: cat.colorHex))
                .clipShape(Circle())
            
            Text(cat.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            if isCustom {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Bawaan")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
    
    private func deleteCategory(_ cat: Category) {
        guard !cat.isDefault else { return }
        modelContext.delete(cat)
        try? modelContext.save()
        categoryToDelete = nil
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
}
