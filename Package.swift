// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Novakey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "novakey", targets: ["Novakey"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "Novakey",
            dependencies: [
                "NovakeyCore",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "NovakeyCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "NovakeyTests",
            dependencies: ["NovakeyCore"]
        )
    ]
) 

// 補完がかってにされる　

// 補完が