import Foundation

/// Utility untuk memformat mata uang Rupiah dan tanggal dalam Bahasa Indonesia.
public enum CurrencyFormatter {
    private static let rupiahFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp "
        formatter.currencyGroupingSeparator = "."
        formatter.currencyDecimalSeparator = ","
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: "id_ID")
        return formatter
    }()
    
    private static let indonesianLocale = Locale(identifier: "id_ID")
    
    /// Format angka menjadi format Rupiah tanpa desimal, contoh: `Rp 20.000`
    public static func rupiah(_ amount: Double) -> String {
        return rupiahFormatter.string(from: NSNumber(value: amount)) ?? "Rp 0"
    }
    
    /// Format angka integer menjadi format Rupiah tanpa desimal
    public static func rupiah(_ amount: Int) -> String {
        return rupiah(Double(amount))
    }
    
    /// Format tanggal lengkap, contoh: "26 Oktober 2026"
    public static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = indonesianLocale
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    /// Format tanggal singkat, contoh: "26 Okt 2026"
    public static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = indonesianLocale
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    /// Format bulan dan tahun, contoh: "Oktober 2026"
    public static func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = indonesianLocale
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    /// Nama bulan dalam Bahasa Indonesia berdasarkan index 1-12
    public static func monthName(month: Int) -> String {
        guard month >= 1 && month <= 12 else { return "" }
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = month
        components.day = 1
        components.year = 2026
        if let date = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.locale = indonesianLocale
            formatter.dateFormat = "MMMM"
            return formatter.string(from: date)
        }
        return ""
    }
}
