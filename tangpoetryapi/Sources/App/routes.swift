import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    try app.register(collection: AdminController())
    try app.register(collection: UserController())
    
    try poets(app)
    try lyricists(app)
    try search(app)
}

private func poets(_ app: Application) throws {
    try app.register(collection: PoetController())
    try app.register(collection: PoetAuthorController())
}

private func lyricists(_ app: Application) throws {
    try app.register(collection: LyricistController())
}


private func search(_ app: Application) throws {
    try app.register(collection: SearchController())
}
