// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWakeOnLan",
    platforms: [.macOS(.v26)],
    products: [
        .executable(
            name: "swol",
            targets: ["swol"]
        )
    ],
    targets: [
        .executableTarget(
            name: "swol"
        ),
        .testTarget(
            name: "SwiftWakeOnLanTests",
            dependencies: ["swol"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
