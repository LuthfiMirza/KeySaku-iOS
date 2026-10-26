import Foundation
import Speech
import AVFoundation
import SwiftUI
import Observation

/// Model hasil ekstraksi perintah suara menjadi data transaksi
public struct ParsedVoiceTransaction: Equatable {
    public var rawText: String
    public var amount: Double
    public var type: String // "expense" atau "income"
    public var categoryName: String
    public var note: String
    
    public init(
        rawText: String = "",
        amount: Double = 0.0,
        type: String = "expense",
        categoryName: String = "Makanan & Minuman",
        note: String = ""
    ) {
        self.rawText = rawText
        self.amount = amount
        self.type = type
        self.categoryName = categoryName
        self.note = note
    }
}

/// Service untuk menangani Speech-to-Text Bahasa Indonesia & Parsing NLP Sederhana
@Observable
public final class VoiceParserService: @unchecked Sendable {
    public static let shared = VoiceParserService()
    
    public var isRecording: Bool = false
    public var transcribedText: String = ""
    public var parsedResult: ParsedVoiceTransaction? = nil
    public var audioLevel: Float = 0.0 // Skala 0.0 - 1.0 untuk animasi gelombang suara
    public var errorMessage: String? = nil
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    public init() {
        // Gunakan Speech Recognizer dengan Locale Bahasa Indonesia
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID"))
        if speechRecognizer == nil {
            self.speechRecognizer = SFSpeechRecognizer() // Fallback ke default sistem
        }
    }
    
    // MARK: - Izin Akses Mikrofon & Speech
    
    public func requestAuthorization() async -> Bool {
        let speechAuth = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        let micAuth = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        return speechAuth && micAuth
    }
    
    // MARK: - Mulai & Berhenti Rekam
    
    @MainActor
    public func startRecording(availableCategories: [Category] = []) throws {
        // Reset state sebelumnya
        stopRecording()
        
        errorMessage = nil
        transcribedText = ""
        parsedResult = nil
        audioLevel = 0.0
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceParserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gagal menginisialisasi recognition request."])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Pasang Audio Tap untuk audio buffer dan level amplitudo (waveform)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, _) in
            self?.recognitionRequest?.append(buffer)
            
            // Hitung Root Mean Square (RMS) untuk visualisasi level suara
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
            var sum: Float = 0
            for sample in channelDataArray {
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(buffer.frameLength))
            let normalizedLevel = min(max(rms * 10.0, 0.0), 1.0)
            
            Task { @MainActor [weak self] in
                self?.audioLevel = normalizedLevel
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                Task { @MainActor in
                    self.transcribedText = result.bestTranscription.formattedString
                    self.parsedResult = self.parseText(self.transcribedText, categories: availableCategories)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in
                    self.stopRecording()
                }
            }
        }
    }
    
    @MainActor
    public func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        audioLevel = 0.0
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Parsing NLP Bahasa Indonesia
    
    public func parseText(_ text: String, categories: [Category] = []) -> ParsedVoiceTransaction {
        let clean = text.lowercased()
        
        // 1. Deteksi Tipe Transaksi: Pengeluaran vs Pemasukan
        let isIncome = detectIsIncome(text: clean)
        let type = isIncome ? "income" : "expense"
        
        // 2. Ekstraksi Nominal Uang
        let amount = extractIndonesianAmount(from: clean)
        
        // 3. Deteksi Kategori
        let categoryName = detectCategory(from: clean, isIncome: isIncome, categories: categories)
        
        // 4. Catatan Keterangan
        let note = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ParsedVoiceTransaction(
            rawText: text,
            amount: amount,
            type: type,
            categoryName: categoryName,
            note: note.isEmpty ? (isIncome ? "Pemasukan Suara" : "Pengeluaran Suara") : note
        )
    }
    
    private func detectIsIncome(text: String) -> Bool {
        let incomeKeywords = [
            "gaji", "terima gaji", "dapat", "terima", "bonus", "penjualan",
            "masuk", "transfer dari", "untung", "cuan", "hadiah", "thr",
            "investasi", "dividen", "cashback", "pendapatan", "penghasilan"
        ]
        
        for keyword in incomeKeywords {
            if text.contains(keyword) {
                return true
            }
        }
        return false
    }
    
    /// Menemukan nominal uang dari teks campuran kata angka ("dua puluh ribu", "150rb", "1,5 juta", "Rp 50.000")
    public func extractIndonesianAmount(from text: String) -> Double {
        // A. Cek pola angka langsung dengan akhiran: e.g. "1.5jt", "1,5 juta", "20rb", "50k", "50000", "Rp 20.000"
        if let directAmount = extractNumericAmount(from: text) {
            return directAmount
        }
        
        // B. Parse kata-kata angka dalam Bahasa Indonesia
        return parseIndonesianSpokenNumber(from: text)
    }
    
    private func extractNumericAmount(from text: String) -> Double? {
        // Format "Rp 50.000" atau "50.000" atau "20000"
        let patterns: [(regex: String, multiplier: Double)] = [
            (#"(\d+(?:[.,]\d+)?)\s*(?:juta|jt)"#, 1_000_000.0),
            (#"(\d+(?:[.,]\d+)?)\s*(?:ribu|rb|k)"#, 1_000.0),
            (#"rp\s*(\d{1,3}(?:\.\d{3})+)"#, 1.0),
            (#"(\d{1,3}(?:\.\d{3})+)"#, 1.0),
            (#"\b(\d{4,9})\b"#, 1.0)
        ]
        
        for item in patterns {
            if let regex = try? NSRegularExpression(pattern: item.regex, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let matchRange = Range(match.range(at: 1), in: text) {
                    var numString = String(text[matchRange])
                    // Hapus titik pemisah ribuan jika ada
                    numString = numString.replacingOccurrences(of: ".", with: "")
                    numString = numString.replacingOccurrences(of: ",", with: ".")
                    if let value = Double(numString) {
                        return value * item.multiplier
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Mengonversi kata bilangan lisan ("dua puluh lima ribu", "seratus lima puluh ribu", "tiga juta")
    public func parseIndonesianSpokenNumber(from text: String) -> Double {
        let words = text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        let wordValues: [String: Double] = [
            "setengah": 0.5,
            "seperempat": 0.25,
            "satu": 1, "se": 1,
            "dua": 2,
            "tiga": 3,
            "empat": 4,
            "lima": 5,
            "enam": 6,
            "tujuh": 7,
            "delapan": 8,
            "sembilan": 9,
            "sepuluh": 10,
            "sebelas": 11,
            "seratus": 100,
            "seribu": 1000,
            "sejuta": 1000000
        ]
        
        var total: Double = 0
        var currentChunk: Double = 0
        var foundNumber = false
        
        for word in words {
            if let val = wordValues[word] {
                foundNumber = true
                if word == "seratus" {
                    currentChunk += 100
                } else if word == "seribu" {
                    if currentChunk == 0 { currentChunk = 1 }
                    total += currentChunk * 1000
                    currentChunk = 0
                } else if word == "sejuta" {
                    if currentChunk == 0 { currentChunk = 1 }
                    total += currentChunk * 1000000
                    currentChunk = 0
                } else {
                    currentChunk += val
                }
            } else if word == "belas" {
                foundNumber = true
                currentChunk += 10
            } else if word == "puluh" {
                foundNumber = true
                currentChunk *= 10
            } else if word == "ratus" {
                foundNumber = true
                currentChunk *= 100
            } else if word == "ribu" || word == "rb" {
                foundNumber = true
                if currentChunk == 0 { currentChunk = 1 }
                total += currentChunk * 1000
                currentChunk = 0
            } else if word == "juta" || word == "jt" {
                foundNumber = true
                if currentChunk == 0 { currentChunk = 1 }
                total += currentChunk * 1000000
                currentChunk = 0
            } else if let num = Double(word) {
                foundNumber = true
                currentChunk += num
            }
        }
        
        total += currentChunk
        return foundNumber ? total : 0.0
    }
    
    private func detectCategory(from text: String, isIncome: Bool, categories: [Category]) -> String {
        if isIncome {
            if text.contains("investasi") || text.contains("saham") || text.contains("dividen") || text.contains("reksadana") || text.contains("crypto") {
                return "Investasi"
            }
            if text.contains("bonus") || text.contains("hadiah") || text.contains("thr") {
                return "Bonus"
            }
            if text.contains("jual") || text.contains("penjualan") || text.contains("dagang") {
                return "Penjualan"
            }
            return "Gaji"
        } else {
            // Expense rules
            let mappings: [(keywords: [String], category: String)] = [
                (["makan", "minum", "nasi", "bakso", "kopi", "kafe", "resto", "martabak", "gofood", "grabfood", "jajan", "snack", "warung", "sarapan", "siang", "malam"], "Makanan & Minuman"),
                (["bensin", "pertalite", "pertamax", "gojek", "grab", "ojol", "krl", "mrt", "bus", "parkir", "tol", "servis", "motor", "mobil", "angkot"], "Transportasi"),
                (["belanja", "baju", "sepatu", "alfamart", "indomaret", "shopee", "tokopedia", "sabun", "odol", "swalayan", "supermarket", "mall"], "Belanja"),
                (["listrik", "pln", "pdam", "air", "wifi", "indihome", "internet", "pulsa", "kuota", "bpjs", "pbb", "sewa", "kontrakan", "tagihan"], "Tagihan & Utilitas"),
                (["nonton", "bioskop", "netflix", "spotify", "game", "steam", "liburan", "hotel", "tiket", "karaoke", "jalan"], "Hiburan"),
                (["obat", "apotek", "dokter", "rumah sakit", "klinik", "vitamin", "periksa", "medis"], "Kesehatan"),
                (["sekolah", "kursus", "buku", "kuliah", "spp", "les"], "Pendidikan")
            ]
            
            for item in mappings {
                for kw in item.keywords {
                    if text.contains(kw) {
                        return item.category
                    }
                }
            }
            
            return "Lainnya"
        }
    }
}
