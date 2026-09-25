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
            exclude: ["Resources", "Info.plist"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "TinyLogTests",
            dependencies: ["TinyLog"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
