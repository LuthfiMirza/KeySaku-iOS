import Foundation

/// DTO Model untuk data Pengguna dari Laravel Sanctum API.
public struct User: Codable, Identifiable, Equatable {
    public let id: Int
    public var name: String
    public var email: String
    public var emailVerifiedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case emailVerifiedAt = "email_verified_at"
    }
    
    public init(id: Int, name: String, email: String, emailVerifiedAt: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.emailVerifiedAt = emailVerifiedAt
    }
}

/// DTO Response untuk Autentikasi Laravel Sanctum (/api/v1/login & /api/v1/register)
public struct AuthResponse: Codable {
    public let token: String?
    public let user: User?
    public let message: String?
}
