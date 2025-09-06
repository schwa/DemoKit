// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DemoKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "DemoKit",
            targets: ["DemoKit"]
        ),
    ],
    targets: [
        .target(
            name: "DemoKit"
        ),
        .testTarget(
            name: "DemoKitTests",
            dependencies: ["DemoKit"]
        ),
    ]
)
