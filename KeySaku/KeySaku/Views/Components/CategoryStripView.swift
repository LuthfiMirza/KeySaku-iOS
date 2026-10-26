import SwiftUI

/// Baris Kategori Horizontal Interaktif (Sesuai Referensi Desain "Categories See All")
public struct CategoryStripView: View {
    public var categories: [Category]
    @Binding var selectedCategoryName: String?
    public var onSelect: (String?) -> Void
    
    public init(
        categories: [Category],
        selectedCategoryName: Binding<String?>,
        onSelect: @escaping (String?) -> Void = { _ in }
    ) {
        self.categories = categories
        self._selectedCategoryName = selectedCategoryName
        self.onSelect = onSelect
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                // Item "Semua"
                categoryItem(
                    title: "Semua",
                    icon: "square.grid.2x2.fill",
                    colorHex: "#10B981",
                    isSelected: selectedCategoryName == nil
                ) {
                    selectedCategoryName = nil
                    onSelect(nil)
                }
                
                // Item Kategori Dinamis
                ForEach(categories) { cat in
                    categoryItem(
                        title: cat.name,
                        icon: cat.icon,
                        colorHex: cat.colorHex,
                        isSelected: selectedCategoryName == cat.name
                    ) {
                        if selectedCategoryName == cat.name {
                            selectedCategoryName = nil
                            onSelect(nil)
                        } else {
                            selectedCategoryName = cat.name
                            onSelect(cat.name)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private func categoryItem(
        title: String,
        icon: String,
        colorHex: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticHelper.light()
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: colorHex) : Color(hex: colorHex).opacity(0.15))
                        .frame(width: 52, height: 52)
                        .shadow(color: isSelected ? Color(hex: colorHex).opacity(0.35) : .clear, radius: 6, y: 3)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? .white : Color(hex: colorHex))
                }
                
                Text(title)
                    .font(.caption2.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color(hex: colorHex) : .secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 68)
            }
        }
        .buttonStyle(.plain)
    }
}
