// swift-tools-version:6.0
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
        ),
        .testTarget(
            name: "StockBarTests",
            dependencies: ["StockBar"],
            path: "Tests/StockBarTests"
        )
    ],
    // 仅提升工具链版本以启用 swift-testing(Testing 框架随工具链提供),
    // 语言模式仍保持 Swift 5,避免源码被动迁移到 Swift 6 严格并发检查。
    swiftLanguageModes: [.v5]
)
