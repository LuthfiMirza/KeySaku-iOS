import SwiftUI
import SwiftData

/// Lembar Pencatatan Transaksi menggunakan Perintah Suara Bahasa Indonesia
public struct VoiceTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Account.name) private var accounts: [Account]
    
    @State private var voiceService = VoiceParserService.shared
    @State private var isAuthorized: Bool = false
    @State private var permissionAlert: Bool = false
    
    // Editable Parsed Fields
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedCategoryName: String = "Makanan & Minuman"
    @State private var selectedAccountId: UUID? = nil
    @State private var transactionDate: Date = Date()
    @State private var errorMessage: String? = nil
    
    // Quick Simulation Examples (berguna saat test di simulator tanpa mic fisik)
    private let samplePhrases = [
        "Beli makan siang dua puluh lima ribu",
        "Bensin motor lima puluh ribu",
        "Belanja bulanan tiga ratus ribu",
        "Terima gaji lima juta lima ratus ribu",
        "Nongkrong ngopi tiga puluh lima ribu"
    ]
    
    public init() {}
    
    private var availableCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Animated Waveform & Mic Circle
                    VStack(spacing: 16) {
                        ZStack {
                            // Pulsing wave rings when recording
                            if voiceService.isRecording {
                                Circle()
                                    .fill(Color(hex: "#10B981").opacity(0.12))
                                    .frame(width: 140 + CGFloat(voiceService.audioLevel * 60),
                                           height: 140 + CGFloat(voiceService.audioLevel * 60))
                                    .animation(.easeOut(duration: 0.2), value: voiceService.audioLevel)
                                
                                Circle()
                                    .fill(Color(hex: "#10B981").opacity(0.25))
                                    .frame(width: 110 + CGFloat(voiceService.audioLevel * 40),
                                           height: 110 + CGFloat(voiceService.audioLevel * 40))
                                    .animation(.easeOut(duration: 0.2), value: voiceService.audioLevel)
                            }
                            
                            // Mic Button
                            Button {
                                toggleRecording()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(voiceService.isRecording ? Color.red : Color(hex: "#10B981"))
                                        .frame(width: 84, height: 84)
                                        .shadow(color: (voiceService.isRecording ? Color.red : Color(hex: "#10B981")).opacity(0.4), radius: 12, y: 6)
                                    
                                    Image(systemName: voiceService.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(height: 180)
                        
                        // Status Text
                        VStack(spacing: 4) {
                            Text(voiceService.isRecording ? "Mendengarkan ucapan Anda..." : "Ketuk mikrofon untuk mulai bicara")
                                .font(.headline)
                                .foregroundStyle(voiceService.isRecording ? Color.red : .primary)
                            
                            Text("Bicara santai, contoh: 'Beli nasi goreng 25 ribu pakai Tunai'")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                    
                    // MARK: - Live Transcription Card
                    if !voiceService.transcribedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundStyle(Color(hex: "#10B981"))
                                Text("Hasil Ucapan")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            Text("\"\(voiceService.transcribedText)\"")
                                .font(.body.weight(.medium))
                                .italic()
                                .foregroundStyle(.primary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Simulation Chips (Untuk kemudahan pengujian)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Atau pilih contoh kalimat:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(samplePhrases, id: \.self) { phrase in
                                    Button {
                                        applyParsedText(phrase)
                                    } label: {
                                        Text(phrase)
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
                    
                    // MARK: - Hasil Ekstraksi Transaksi (Editable Review)
                    if !amountText.isEmpty || !title.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Hasil Analisis Transaksi")
                                    .font(.headline)
                                Spacer()
                                Text("Otomatis Terisi")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "#10B981").opacity(0.15))
                                    .foregroundStyle(Color(hex: "#10B981"))
                                    .clipShape(Capsule())
                            }
                            
                            // Tipe Transaksi
                            Picker("Tipe", selection: $selectedType) {
                                Text("Pengeluaran").tag("expense")
                                Text("Pemasukan").tag("income")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedType) { _, newType in
                                if let firstCat = categories.first(where: { $0.type == newType }) {
                                    selectedCategoryName = firstCat.name
                                }
                            }
                            
                            // Nominal
                            HStack {
                                Text("Nominal")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("Rp")
                                        .foregroundStyle(.secondary)
                                    TextField("0", text: $amountText)
                                        .font(.title3.bold())
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            .padding(12)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            // Judul Catatan
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Judul Catatan")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Keterangan transaksi", text: $title)
                                    .padding(12)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            // Pilihan Kategori
                            HStack {
                                Text("Kategori")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Kategori", selection: $selectedCategoryName) {
                                    ForEach(availableCategories) { cat in
                                        Label(cat.name, systemImage: cat.icon).tag(cat.name)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(12)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            // Pilihan Akun Sumber/Tujuan
                            HStack {
                                Text("Akun")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Akun", selection: $selectedAccountId) {
                                    ForEach(accounts) { acc in
                                        Text("\(acc.name) (\(CurrencyFormatter.rupiah(acc.balance)))").tag(Optional(acc.id))
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(12)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                        
                        // Tombol Simpan Instan
                        Button {
                            saveVoiceTransaction()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Simpan Transaksi Instan")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isFormValid ? Color(hex: "#10B981") : Color.gray.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isFormValid)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Catat Suara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") {
                        voiceService.stopRecording()
                        dismiss()
                    }
                }
            }
            .task {
                isAuthorized = await voiceService.requestAuthorization()
                if let defaultAcc = accounts.first {
                    selectedAccountId = defaultAcc.id
                }
            }
            .onChange(of: voiceService.parsedResult) { _, newResult in
                if let parsed = newResult {
                    applyParsedObject(parsed)
                }
            }
            .alert("Izin Diperlukan", isPresented: $permissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Buka Pengaturan iOS dan izinkan KeySaku mengakses Mikrofon & Pengenalan Suara.")
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isFormValid: Bool {
        let amount = Double(amountText.filter { $0.isNumber }) ?? 0.0
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               amount > 0 &&
               selectedAccountId != nil
    }
    
    private func toggleRecording() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            guard isAuthorized else {
                permissionAlert = true
                return
            }
            do {
                try voiceService.startRecording(availableCategories: categories)
            } catch {
                errorMessage = "Gagal memulai rekaman suara: \(error.localizedDescription)"
            }
        }
    }
    
    private func applyParsedText(_ phrase: String) {
        let parsed = voiceService.parseText(phrase, categories: categories)
        voiceService.transcribedText = phrase
        applyParsedObject(parsed)
    }
    
    private func applyParsedObject(_ parsed: ParsedVoiceTransaction) {
        title = parsed.note
        selectedType = parsed.type
        if parsed.amount > 0 {
            amountText = String(format: "%.0f", parsed.amount)
        }
        
        // Cek kecocokan kategori dengan daftar kategori sistem
        if let matched = categories.first(where: { $0.name.localizedCaseInsensitiveContains(parsed.categoryName) && $0.type == parsed.type }) {
            selectedCategoryName = matched.name
        } else if let fallback = categories.first(where: { $0.type == parsed.type }) {
            selectedCategoryName = fallback.name
        }
    }
    
    private func saveVoiceTransaction() {
        guard let accountId = selectedAccountId,
              let account = accounts.first(where: { $0.id == accountId }) else {
            errorMessage = "Pilih akun terlebih dahulu."
            return
        }
        
        guard let amount = Double(amountText.filter { $0.isNumber }), amount > 0 else {
            errorMessage = "Nominal transaksi harus lebih dari Rp 0."
            return
        }
        
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Judul transaksi tidak boleh kosong."
            return
        }
        
        // Panggil TransactionObserver untuk auto-update saldo Akun secara atomik
        TransactionObserver.shared.createTransaction(
            title: cleanTitle,
            amount: amount,
            type: selectedType,
            categoryName: selectedCategoryName,
            account: account,
            date: transactionDate,
            in: modelContext
        )
        
        HapticHelper.success()
        dismiss()
    }
}

#Preview {
    VoiceTransactionSheet()
}
