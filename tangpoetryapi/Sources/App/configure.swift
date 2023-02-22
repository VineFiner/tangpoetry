import Fluent
import FluentMySQLDriver
import FluentSQLiteDriver
import QueueMemoryDriver
import SwiftSMTPVapor
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors)
    
    // 添加角色中间件
    app.middleware.use(UserRoleMiddleware())
    //
    app.databases.use(.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        ,tlsConfiguration: .makePreSharedKeyConfiguration()
    ), as: .mysql)
    
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    // MARK: App Config
    app.config = .environment
    
    // MARK: Email, 在 app config 之后
    let emailConfig = SwiftSMTPVapor.Configuration.init(server:
        .init(hostname: app.config.noReplayEmailHostName, port: 465, encryption: .ssl), credentials:
        .init(username: app.config.noReplayEmailUserName,
              password: app.config.noReplayEmailPassword))
    app.swiftSMTP.initialize(with: emailConfig)
    
    try migrations(app)
    
    /// 这里根据环境进行配置
    if app.environment == .development {
        app.databases.default(to: .sqlite)
        try app.autoMigrate().wait()
    } else {
        app.databases.default(to: .mysql)
    }
    
    // register routes
    try routes(app)
    
    /// config jobs
    try queues(app)
    
    /// config server
    try services(app)
    
    if app.environment == .development {
        // 开机自动执行任务
        try app.queues.startInProcessJobs()
    } else {
        // 开机自动执行任务
        try app.queues.startInProcessJobs()
    }
    // commands
    try configCommands(app)
}
