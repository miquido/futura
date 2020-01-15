// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Futura",
    products: [
        .library(
            name: "Futura",
            targets: ["Futura"]
        ),
        .library(
            name: "FuturaTest",
            targets: ["FuturaTest"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Futura",
            dependencies: []),
        .target(
            name: "FuturaTest",
            dependencies: ["Futura"]),
        .testTarget(
            name: "FuturaPerformanceTests",
            dependencies: ["Futura", "FuturaTest"]),
        .testTarget(
            name: "FuturaTests",
            dependencies: ["Futura", "FuturaTest"]),
    ]
)
