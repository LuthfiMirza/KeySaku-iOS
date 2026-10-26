import Foundation

/// Konfigurasi endpoint REST API Laravel 12 KeySaku
public struct APIConfig {
    /// URL Server default. Bisa diganti ke http://localhost:8000/api/v1 saat uji coba lokal.
    public static var baseURL: String {
        get {
            UserDefaults.standard.string(forKey: "keysaku_api_base_url") ?? "https://keysaku.com/api/v1"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "keysaku_api_base_url")
        }
    }
    
    // Endpoint Auth
    public static let loginEndpoint = "/login"
    public static let registerEndpoint = "/register"
    public static let logoutEndpoint = "/logout"
    
    // Endpoint Sync & Resource
    public static let syncEndpoint = "/sync"
    public static let accountsEndpoint = "/accounts"
    public static let categoriesEndpoint = "/categories"
    public static let transactionsEndpoint = "/transactions"
    public static let budgetsEndpoint = "/budgets"
    public static let goalsEndpoint = "/goals"
    
    /// Membuat URLRequest dengan header standar Accept & Content-Type: application/json
    public static func makeRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = KeychainHelper.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        request.timeoutInterval = 15.0
        return request
    }
}
