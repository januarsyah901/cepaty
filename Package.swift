// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Cepaty",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Cepaty", targets: ["Cepaty"])
    ],
    targets: [
        .executableTarget(name: "Cepaty"),
        .testTarget(name: "CepatyTests", dependencies: ["Cepaty"])
    ]
)
