import SwiftUI
import SwiftData

/// Tampilan Manajemen Target Tabungan (Savings Goals)
public struct ManageGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoal.deadline) private var allGoals: [SavingsGoal]
    
    @State private var filterStatus: GoalFilter = .all
    @State private var showingAddSheet: Bool = false
    @State private var goalToEdit: SavingsGoal? = nil
    @State private var goalForContribution: SavingsGoal? = nil
    @State private var goalToDelete: SavingsGoal? = nil
    @State private var showingDeleteAlert: Bool = false
    
    public enum GoalFilter: String, CaseIterable, Identifiable {
        case all = "Semua"
        case active = "Berjalan"
        case completed = "Tercapai"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    private var filteredGoals: [SavingsGoal] {
        switch filterStatus {
        case .all:
            return allGoals
        case .active:
            return allGoals.filter { !$0.isCompleted }
        case .completed:
            return allGoals.filter { $0.isCompleted }
        }
    }
    
    private var totalTarget: Double {
        allGoals.reduce(0) { $0 + $1.targetAmount }
    }
    
    private var totalCollected: Double {
        allGoals.reduce(0) { $0 + $1.currentAmount }
    }
    
    private var overallRatio: Double {
        guard totalTarget > 0 else { return 0.0 }
        return min(max(totalCollected / totalTarget, 0.0), 1.0)
    }
    
    private var overallPercentage: Int {
        Int(overallRatio * 100.0)
    }
    
    private var completedCount: Int {
        allGoals.filter { $0.isCompleted }.count
    }
    
    private var activeCount: Int {
        allGoals.filter { !$0.isCompleted }.count
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Ringkasan Keseluruhan
                if !allGoals.isEmpty {
                    summaryCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    // Filter Status
                    Picker("Filter Status", selection: $filterStatus) {
                        ForEach(GoalFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Daftar Target Tabungan
                if allGoals.isEmpty {
                    emptyGoalsView
                } else if filteredGoals.isEmpty {
                    ContentUnavailableView(
                        "Tidak Ada Tabungan",
                        systemImage: "target",
                        description: Text("Tidak ada target tabungan dengan status '\(filterStatus.rawValue)'.")
                    )
                } else {
                    List {
                        ForEach(filteredGoals) { goal in
                            goalCard(for: goal)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        goalToDelete = goal
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Hapus", systemImage: "trash.fill")
                                    }
                                    
                                    Button {
                                        goalToEdit = goal
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
            .navigationTitle("Target Tabungan")
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
                GoalFormSheet()
            }
            .sheet(item: $goalToEdit) { goal in
                GoalFormSheet(goalToEdit: goal)
            }
            .sheet(item: $goalForContribution) { goal in
                AddContributionSheet(goal: goal)
            }
            .confirmationDialog(
                "Hapus Target Tabungan?",
                isPresented: $showingDeleteAlert,
                titleVisibility: .visible,
                presenting: goalToDelete
            ) { goal in
                Button("Hapus", role: .destructive) {
                    deleteGoal(goal)
                }
                Button("Batal", role: .cancel) {}
            } message: { goal in
                Text("Target tabungan '\(goal.title)' akan dihapus permanen.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Tabungan Terkumpul")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyFormatter.rupiah(totalCollected))
                        .font(.title2.bold())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Dari Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyFormatter.rupiah(totalTarget))
                        .font(.subheadline.weight(.semibold))
                }
            }
            
            // Progress Bar Visual
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#10B981"))
                        .frame(width: min(proxy.size.width * CGFloat(overallRatio), proxy.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(overallPercentage)% Terkumpul")
                    .font(.caption2.bold())
                    .foregroundStyle(Color(hex: "#10B981"))
                
                Spacer()
                
                Text("\(completedCount) Tercapai • \(activeCount) Berjalan")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func goalCard(for goal: SavingsGoal) -> some View {
        let isDone = goal.isCompleted
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: goal.deadline).day ?? 0
        
        VStack(alignment: .leading, spacing: 12) {
            // Header Baris: Ikon, Judul, Badge Deadline
            HStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.title3)
                    .frame(width: 42, height: 42)
                    .background(isDone ? Color(hex: "#10B981").opacity(0.18) : Color.blue.opacity(0.15))
                    .foregroundStyle(isDone ? Color(hex: "#10B981") : Color.blue)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Target: \(CurrencyFormatter.rupiah(goal.targetAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status Deadline Badge
                if isDone {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Tercapai")
                    }
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#10B981").opacity(0.15))
                    .foregroundStyle(Color(hex: "#10B981"))
                    .clipShape(Capsule())
                } else if daysLeft < 0 {
                    Text("Lewat Deadline")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                } else {
                    Text("Sisa \(daysLeft) hari")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
            }
            
            // Progress Bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 7)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isDone ? Color(hex: "#10B981") : Color(hex: "#3B82F6"))
                        .frame(width: min(proxy.size.width * CGFloat(goal.progressRatio), proxy.size.width), height: 7)
                }
            }
            .frame(height: 7)
            
            // Info Terkumpul & Sisa
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Terkumpul")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.rupiah(goal.currentAmount))
                        .font(.caption.bold())
                        .foregroundStyle(isDone ? Color(hex: "#10B981") : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Progres")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(Int(goal.progressPercentage))%")
                        .font(.caption.bold())
                        .foregroundStyle(isDone ? Color(hex: "#10B981") : Color(hex: "#3B82F6"))
                }
            }
            
            // Tombol Aksi Tambah Tabungan & Menu
            HStack(spacing: 8) {
                Button {
                    goalForContribution = goal
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Tambah Tabungan")
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#10B981").opacity(0.12))
                    .foregroundStyle(Color(hex: "#10B981"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    goalToEdit = goal
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemFill))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var emptyGoalsView: some View {
        ContentUnavailableView {
            Label("Belum Ada Target Tabungan", systemImage: "target")
        } description: {
            Text("Mulai rencanakan masa depan keluarga seperti dana darurat, liburan, atau pembelian impian.")
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Label("Buat Target Pertama", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#10B981"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func deleteGoal(_ goal: SavingsGoal) {
        modelContext.delete(goal)
        try? modelContext.save()
        goalToDelete = nil
    }
}

#Preview {
    ManageGoalsView()
}
