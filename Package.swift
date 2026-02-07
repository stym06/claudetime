// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeTime",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/dagronf/DSFSparkline", from: "7.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ClaudeTime",
            dependencies: ["DSFSparkline"],
            path: "Sources/ClaudeTime"
        )
    ]
)
