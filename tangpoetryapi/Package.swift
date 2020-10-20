// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "tangpoetry",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/queues.git", from: "1.0.0"),
        
        // product
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0"),
        // develop
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/sersoft-gmbh/SwiftSMTP.git", from: "2.0.0-rc"),
    ],
    targets: [
        .target(name: "QueueMemoryDriver",dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Queues", package: "queues")
            ]
        ),
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "Vapor", package: "vapor"),
                
                // product
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                // develop
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "SwiftSMTPVapor", package: "SwiftSMTP"),
                "QueueMemoryDriver"
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
