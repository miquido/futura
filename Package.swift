// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Futura",
    products: [
        .library(
            name: "Futura",
            targets: ["Futura"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Futura",
            dependencies: []),
        .testTarget(
            name: "FuturaPerformanceTests",
            dependencies: ["Futura"]),
        .testTarget(
            name: "FuturaTests",
            dependencies: ["Futura"]),
    ]
)
