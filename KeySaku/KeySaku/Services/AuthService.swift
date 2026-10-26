import Foundation
import SwiftUI

/// Layanan autentikasi pengguna ke backend Laravel 12 Sanctum & Mode Offline / Demo Lokal
@Observable
@MainActor
public final class AuthService {
    public static let shared = AuthService()
    
    public var isAuthenticated: Bool = false
    public var isOfflineMode: Bool = false
    public var currentUser: User? = nil
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let offlineModeKey = "keysaku_is_offline_mode"
    private let userDefaultsUserKey = "keysaku_stored_user"
    
    private init() {
        checkStoredSession()
    }
    
    /// Cek sesi yang tersimpan di Keychain / UserDefaults saat aplikasi dibuka
    public func checkStoredSession() {
        if UserDefaults.standard.bool(forKey: offlineModeKey) {
            self.isOfflineMode = true
            self.isAuthenticated = true
            self.currentUser = loadStoredUser() ?? User(id: 0, name: "Keluarga KeySaku", email: "lokal@keysaku.app")
            return
        }
        
        if let token = KeychainHelper.shared.getToken(), !token.isEmpty {
            self.isAuthenticated = true
            self.currentUser = loadStoredUser()
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    /// Masuk ke Mode Offline / Demo Lokal (Bypass tanpa koneksi server Laravel)
    public func enterOfflineMode() {
        self.isOfflineMode = true
        self.isAuthenticated = true
        self.errorMessage = nil
        let offlineUser = User(id: 0, name: "Keluarga KeySaku (Offline)", email: "offline@keysaku.local")
        self.currentUser = offlineUser
        saveStoredUser(offlineUser)
        UserDefaults.standard.set(true, forKey: offlineModeKey)
    }
    
    /// Login ke server Laravel 12 via POST /api/v1/login
    public func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let bodyPayload: [String: String] = [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: bodyPayload),
              let request = APIConfig.makeRequest(
                endpoint: APIConfig.loginEndpoint,
                method: "POST",
                body: jsonData,
                requiresAuth: false
              ) else {
            errorMessage = "Gagal menyusun data request ke server."
            return false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Respon server tidak valid."
                return false
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                if let authResponse = try? decoder.decode(AuthResponse.self, from: data),
                   let token = authResponse.token {
                    KeychainHelper.shared.saveToken(token)
                    self.currentUser = authResponse.user
                    if let user = authResponse.user {
                        saveStoredUser(user)
                    }
                    self.isOfflineMode = false
                    UserDefaults.standard.set(false, forKey: offlineModeKey)
                    self.isAuthenticated = true
                    return true
                } else {
                    errorMessage = "Format respon login tidak sesuai."
                    return false
                }
            } else {
                let serverMessage = parseErrorMessage(from: data)
                errorMessage = serverMessage ?? "Email atau kata sandi salah (Status: \(httpResponse.statusCode))."
                return false
            }
        } catch {
            errorMessage = "Tidak dapat terhubung ke server: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Registrasi akun baru via POST /api/v1/register
    public func register(name: String, email: String, password: String, passwordConfirmation: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard password == passwordConfirmation else {
            errorMessage = "Konfirmasi kata sandi tidak cocok."
            return false
        }
        
        let bodyPayload: [String: String] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "password_confirmation": passwordConfirmation
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: bodyPayload),
              let request = APIConfig.makeRequest(
                endpoint: APIConfig.registerEndpoint,
                method: "POST",
                body: jsonData,
                requiresAuth: false
              ) else {
            errorMessage = "Gagal menyusun data registrasi."
            return false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Respon server tidak valid."
                return false
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let decoder = JSONDecoder()
                if let authResponse = try? decoder.decode(AuthResponse.self, from: data),
                   let token = authResponse.token {
                    KeychainHelper.shared.saveToken(token)
                    self.currentUser = authResponse.user
                    if let user = authResponse.user {
                        saveStoredUser(user)
                    }
                    self.isOfflineMode = false
                    UserDefaults.standard.set(false, forKey: offlineModeKey)
                    self.isAuthenticated = true
                    return true
                } else {
                    errorMessage = "Pendaftaran berhasil, silakan coba login."
                    return false
                }
            } else {
                let serverMessage = parseErrorMessage(from: data)
                errorMessage = serverMessage ?? "Pendaftaran gagal (Status: \(httpResponse.statusCode))."
                return false
            }
        } catch {
            errorMessage = "Gagal terhubung ke server: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Logout dan hapus token dari Keychain
    public func logout() async {
        if !isOfflineMode, let request = APIConfig.makeRequest(
            endpoint: APIConfig.logoutEndpoint,
            method: "POST"
        ) {
            _ = try? await URLSession.shared.data(for: request)
        }
        
        KeychainHelper.shared.deleteToken()
        UserDefaults.standard.set(false, forKey: offlineModeKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsUserKey)
        self.currentUser = nil
        self.isOfflineMode = false
        self.isAuthenticated = false
    }
    
    // MARK: - Helper Penyimpanan User Lokal
    private func saveStoredUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsUserKey)
        }
    }
    
    private func loadStoredUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsUserKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let message = json["message"] as? String {
            return message
        }
        if let errors = json["errors"] as? [String: [String]], let firstError = errors.values.first?.first {
            return firstError
        }
        return nil
    }
}
