import SwiftUI
import SwiftData

/// Lembar Tambah Kontribusi Tabungan
/// Sesuai Aturan Bisnis AGENTS.md: HANYA menambah nominal currentAmount pada SavingsGoal dan TIDAK memotong saldo Account mana pun.
public struct AddContributionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var goal: SavingsGoal
    
    @State private var amountText: String = ""
    @State private var errorMessage: String? = nil
    
    private let quickAmounts: [Double] = [
        50_000, 100_000, 250_000, 500_000, 1_000_000, 2_000_000
    ]
    
    public init(goal: SavingsGoal) {
        self.goal = goal
    }
    
    private var inputAmount: Double {
        Double(amountText.filter { $0.isNumber }) ?? 0.0
    }
    
    private var projectedAmount: Double {
        goal.currentAmount + inputAmount
    }
    
    private var projectedRatio: Double {
        guard goal.targetAmount > 0 else { return 0.0 }
        return min(max(projectedAmount / goal.targetAmount, 0.0), 1.0)
    }
    
    private var projectedPercentage: Int {
        guard goal.targetAmount > 0 else { return 0 }
        return Int((projectedAmount / goal.targetAmount) * 100.0)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Informasi Target Tabungan
                    VStack(spacing: 12) {
                        Image(systemName: goal.icon)
                            .font(.system(size: 32))
                            .frame(width: 64, height: 64)
                            .background(Color(hex: "#10B981").opacity(0.15))
                            .foregroundStyle(Color(hex: "#10B981"))
                            .clipShape(Circle())
                        
                        VStack(spacing: 4) {
                            Text(goal.title)
                                .font(.title3.weight(.bold))
                            
                            Text("Target: \(CurrencyFormatter.rupiah(goal.targetAmount))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Card Status Saat Ini vs Setelah Ditambah
                    VStack(spacing: 10) {
                        HStack {
                            Text("Terkumpul Saat Ini")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(CurrencyFormatter.rupiah(goal.currentAmount))
                                .font(.subheadline.weight(.semibold))
                        }
                        
                        ProgressView(value: goal.progressRatio)
                            .tint(Color(hex: "#10B981"))
                        
                        if inputAmount > 0 {
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Setelah Ditambah")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(CurrencyFormatter.rupiah(projectedAmount))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(hex: "#10B981"))
                            }
                            
                            ProgressView(value: projectedRatio)
                                .tint(Color(hex: "#10B981"))
                            
                            HStack {
                                Text("\(projectedPercentage)% dari target")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color(hex: "#10B981"))
                                Spacer()
                                let remaining = max(goal.targetAmount - projectedAmount, 0.0)
                                if remaining == 0 {
                                    Text("🎉 Target Tercapai!")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color(hex: "#10B981"))
                                } else {
                                    Text("Kurang \(CurrencyFormatter.rupiah(remaining))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Input Nominal
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nominal yang Ditabung")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Rp")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.secondary)
                            
                            TextField("0", text: $amountText)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Quick Amount Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickAmounts, id: \.self) { val in
                                    Button {
                                        let current = Double(amountText.filter { $0.isNumber }) ?? 0.0
                                        amountText = String(format: "%.0f", current + val)
                                    } label: {
                                        Text("+\(CurrencyFormatter.rupiah(val))")
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(.tertiarySystemFill))
                                            .foregroundStyle(.primary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Catatan Bisnis AGENTS.md
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color(hex: "#10B981"))
                        Text("Kontribusi ini melacak progres tabungan tanpa memotong saldo akun secara otomatis.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    // Tombol Simpan
                    Button {
                        submitContribution()
                    } label: {
                        Text("Simpan Tabungan")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(inputAmount > 0 ? Color(hex: "#10B981") : Color.gray.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(inputAmount <= 0)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Tambah Tabungan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitContribution() {
        guard inputAmount > 0 else {
            errorMessage = "Masukkan nominal tabungan yang valid."
            return
        }
        
        goal.addContribution(amount: inputAmount)
        try? modelContext.save()
        dismiss()
    }
}
