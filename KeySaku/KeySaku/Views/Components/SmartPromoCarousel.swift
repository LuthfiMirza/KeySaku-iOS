import SwiftUI

/// Model item kartu carousel wawasan keuangan
public struct SmartPromoItem: Identifiable {
    public var id = UUID()
    public var badge: String
    public var title: String
    public var subtitle: String
    public var buttonText: String
    public var gradientColors: [Color]
    public var icon: String
    public var action: () -> Void
}

/// Carousel Banner Dinamis bergaya Promo Card modern (Sesuai Referensi Desain)
public struct SmartPromoCarousel: View {
    public var items: [SmartPromoItem]
    @State private var currentIndex: Int = 0
    
    public init(items: [SmartPromoItem]) {
        self.items = items
    }
    
    public var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 8) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        bannerCard(for: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)
                
                // Custom Dot Indicator
                if items.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<items.count, id: \.self) { idx in
                            Capsule()
                                .fill(currentIndex == idx ? Color(hex: "#10B981") : Color(.tertiarySystemFill))
                                .frame(width: currentIndex == idx ? 18 : 6, height: 6)
                                .animation(.spring(), value: currentIndex)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
    
    @ViewBuilder
    private func bannerCard(for item: SmartPromoItem) -> some View {
        ZStack(alignment: .bottomTrailing) {
            // Background Gradien
            LinearGradient(
                colors: item.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Background Icon Aksen Transparan
            Image(systemName: item.icon)
                .font(.system(size: 90))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 20, y: 15)
            
            // Konten Teks & Tombol
            VStack(alignment: .leading, spacing: 6) {
                // Badge Kategori Banner
                Text(item.badge.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.22))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                
                Text(item.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2)
                
                Spacer(minLength: 0)
                
                // Action Chip
                Button {
                    HapticHelper.light()
                    item.action()
                } label: {
                    HStack(spacing: 4) {
                        Text(item.buttonText)
                            .font(.caption2.weight(.bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white)
                    .foregroundStyle(item.gradientColors.first ?? Color(hex: "#10B981"))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: (item.gradientColors.first ?? Color.black).opacity(0.2), radius: 8, y: 4)
    }
}
