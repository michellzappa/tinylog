// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinyLog",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "Packages/TinyKit"),
    ],
    targets: [
        .executableTarget(
            name: "TinyLog",
            dependencies: ["TinyKit"],
            path: "Sources/TinyLog",
            exclude: ["Resources"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
