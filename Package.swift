// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScoovaWebhooks",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "ScoovaWebhooks", targets: ["ScoovaWebhooks"]),
    ],
    targets: [
        .target(name: "ScoovaWebhooks", path: "Sources/ScoovaWebhooks"),
        .testTarget(
            name: "ScoovaWebhooksTests",
            dependencies: ["ScoovaWebhooks"],
            path: "Tests/ScoovaWebhooksTests"
        ),
    ]
)
