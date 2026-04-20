// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DarkGram",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/Swiftgram/TDLibKit.git",
            exact: "1.5.2-tdlib-1.8.58-889bdf06"
        )
    ],
    targets: [
        .target(
            name: "DarkGram",
            dependencies: ["TDLibKit"]
        )
    ]
)
