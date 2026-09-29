// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Glazki",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Glazki", path: "Sources/Glazki")
    ]
)
