// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "StockBar",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "StockBar",
            path: "Sources/StockBar"
        )
    ]
)
