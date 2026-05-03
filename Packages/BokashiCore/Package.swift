// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BokashiCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BokashiCore", targets: ["BokashiCore"]),
    ],
    targets: [
        .target(name: "BokashiCore"),
        .testTarget(name: "BokashiCoreTests", dependencies: ["BokashiCore"]),
    ]
)
