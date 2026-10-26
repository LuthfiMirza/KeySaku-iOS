import Foundation
import Security

/// Helper untuk menyimpan, membaca, dan menghapus token autentikasi (Laravel Sanctum) di iOS Keychain secara aman.
public final class KeychainHelper {
    public static let shared = KeychainHelper()
    
    private let defaultTokenKey = "keysaku_sanctum_token"
    private let serviceName = "com.luthfi.KeySaku"
    
    private init() {}
    
    /// Menyimpan token autentikasi ke Keychain
    @discardableResult
    public func saveToken(_ token: String, for key: String? = nil) -> Bool {
        let accountKey = key ?? defaultTokenKey
        guard let data = token.data(using: .utf8) else { return false }
        
        // Hapus token lama terlebih dahulu jika sudah ada
        deleteToken(for: accountKey)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Mengambil token autentikasi dari Keychain
    public func getToken(for key: String? = nil) -> String? {
        let accountKey = key ?? defaultTokenKey
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    /// Menghapus token dari Keychain
    @discardableResult
    public func deleteToken(for key: String? = nil) -> Bool {
        let accountKey = key ?? defaultTokenKey
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
