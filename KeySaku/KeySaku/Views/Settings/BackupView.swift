import SwiftUI
import SwiftData

/// Tampilan Cadangan & Sinkronisasi Data (Cloud Sync & Local JSON Backup)
public struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var accounts: [Account]
    @Query private var categories: [Category]
    @Query private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    @Query private var goals: [SavingsGoal]
    
    @State private var syncService = SyncService.shared
    @State private var generatedBackupUrl: URL? = nil
    @State private var isExporting: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Sinkronisasi Cloud Laravel
                Section("Sinkronisasi Cloud (Laravel API)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(AuthService.shared.isOfflineMode ? Color.orange : Color(hex: "#10B981"))
                                .frame(width: 10, height: 10)
                            
                            Text(AuthService.shared.isOfflineMode ? "Mode Offline Lokal" : "Terhubung ke Server")
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            if syncService.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        Text("Status: \(syncService.lastSyncStatus)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let lastDate = syncService.lastSyncDate {
                            Text("Terakhir sinkron: \(CurrencyFormatter.formatDate(lastDate))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if !AuthService.shared.isOfflineMode {
                        Button {
                            HapticHelper.medium()
                            Task {
                                await syncService.sync(context: modelContext)
                                HapticHelper.success()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(syncService.isSyncing ? "Menyinkronkan..." : "Sinkronkan Sekarang")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "#10B981"))
                        }
                        .disabled(syncService.isSyncing)
                    }
                }
                
                // Section 2: Statistik Data Tersimpan di iPhone
                Section("Ringkasan Data Lokal") {
                    LabeledContent("Total Transaksi", value: "\(transactions.count)")
                    LabeledContent("Total Akun Keuangan", value: "\(accounts.count)")
                    LabeledContent("Total Kategori", value: "\(categories.count)")
                    LabeledContent("Total Alokasi Anggaran", value: "\(budgets.count)")
                    LabeledContent("Total Target Tabungan", value: "\(goals.count)")
                }
                
                // Section 3: Ekspor JSON Lokal
                Section("Cadangan Berkas Lokal (JSON)") {
                    Text("Ekspor seluruh catatan keuangan Anda ke dalam satu berkas file JSON untuk arsip atau transfer mandiri.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let fileUrl = generatedBackupUrl {
                        ShareLink(item: fileUrl) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Bagikan / Simpan Berkas JSON")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#10B981"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        Button {
                            HapticHelper.medium()
                            exportBackupFile()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text(isExporting ? "Membuat Berkas..." : "Buat File Cadangan JSON")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "#10B981"))
                        }
                        .disabled(isExporting)
                    }
                }
            }
            .navigationTitle("Cadangan & Sinkron")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Selesai") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportBackupFile() {
        isExporting = true
        if let url = BackupService.shared.createBackupFile(context: modelContext) {
            generatedBackupUrl = url
            HapticHelper.success()
        } else {
            HapticHelper.error()
        }
        isExporting = false
    }
}

#Preview {
    BackupView()
}
