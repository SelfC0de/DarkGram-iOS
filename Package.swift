// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DarkGram",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/nicegram/TDLibKit.git",
            from: "1.8.17"
        )
    ],
    targets: [
        .target(
            name: "DarkGram",
            dependencies: ["TDLibKit"]
        )
    ]
)
