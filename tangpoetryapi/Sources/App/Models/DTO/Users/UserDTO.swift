import Vapor

struct UserDTO: Content {
    let id: UUID?
    let fullName: String
    let email: String
    let isAdmin: Bool
    let date: Date?
    let isFreeze: Bool
    let userHead: String?
    
    init(id: UUID? = nil, fullName: String, email: String, isAdmin: Bool, isFreeze: Bool, createdAt: Date? = nil, userHead: String? = nil) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.isAdmin = isAdmin
        self.isFreeze = isFreeze
        self.date = createdAt
        self.userHead = AppConfig.environment.apiURL + "/uploads/\(userHead ?? "default.jpg")"
    }
    
    init(from user: User) {
        self.init(id: user.id, fullName: user.fullName, email: user.email, isAdmin: user.isAdmin, isFreeze: user.isFreeze, createdAt: user.createdAt, userHead: user.imageUrl)
    }
}


