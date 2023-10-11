// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "WeatherTalk_Server",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.77.1"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver", from: "4.4.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "APNS", package: "apnswift"),
                .product(name: "APNSCore", package: "apnswift"),
                .product(name: "APNSURLSession", package: "apnswift"),
                .product(name: "APNSTestServer", package: "apnswift"),
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
