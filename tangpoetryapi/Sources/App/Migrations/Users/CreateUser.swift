import Fluent
import Vapor

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users")
            .id()
            .field("full_name", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("is_admin", .bool, .required, .custom("DEFAULT FALSE"))
            .field("is_email_verified", .bool, .required, .custom("DEFAULT FALSE"))
            .field("image_url", .string)
            .unique(on: "email")
            .field("created_at", .string)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}

struct UserSeed: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        var seedUsers: [User] = []
        let password = [UInt8].random(count: 8).base64
        database.logger.info("\(password)")
        if let admin = try? User(fullName: "vine", email: "vine@gmail.com", passwordHash: Bcrypt.hash(password), isAdmin: true, isEmailVerified: true) {
            seedUsers.append(admin)
        }
        /*
        let names = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
        if let names = try? names.compactMap({ (name) -> User in
            let password = [UInt8].random(count: 8).base64
            database.logger.info("\(name):\(password)")
            let user = try User(fullName: name,
                                email: "\(name)@gmail.com",
                passwordHash: Bcrypt.hash(password),
                isAdmin: false,
                isEmailVerified: true)
            return user
        }) {
            seedUsers.append(contentsOf: names)
        }
        */
        return EventLoopFuture.andAllSucceed([
            seedUsers.create(on: database)
        ], on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}
