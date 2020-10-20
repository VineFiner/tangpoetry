import Vapor
import Fluent

final class User: Model, Authenticatable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "full_name")
    var fullName: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "is_admin")
    var isAdmin: Bool
    
    @Field(key: "is_freeze")
    var isFreeze: Bool
    
    @Field(key: "is_email_verified")
    var isEmailVerified: Bool
    
    @Field(key: "image_url")
    var imageUrl: String?
    
    /// 这里是时间戳, Timestamp Format 这里是字符串
    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        fullName: String,
        email: String,
        passwordHash: String,
        isAdmin: Bool = false,
        isFreeze: Bool = false,
        isEmailVerified: Bool = false,
        imageUrl: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.passwordHash = passwordHash
        self.isAdmin = isAdmin
        self.isFreeze = isFreeze
        self.isEmailVerified = isEmailVerified
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

// MARK: Token
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}
