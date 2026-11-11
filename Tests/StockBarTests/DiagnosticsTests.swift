import Foundation
import Testing

@testable import StockBar

struct DiagnosticsTests {
    private let fixedNow = Date(timeIntervalSince1970: 1_760_000_000)  // 2025-10-09T08:53:20Z

    private var fullSnapshot: DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            version: "1.1.0",
            osVersion: "Version 15.1.0 (Build 24B83)",
            languageSetting: "system",
            language: "zh-Hans",
            symbol: "600519.SS",
            quote: Quote(
                symbol: "600519.SS",
                price: 1341.99,
                previousClose: 1355.30,
                currency: "CNY",
                marketTime: Date(timeIntervalSince1970: 1_759_991_400),
                name: "贵州茅台"
            ),
            lastUpdated: Date(timeIntervalSince1970: 1_759_999_000),
            selectedProvider: "Yahoo Finance",
            activeProvider: "EastMoney",
            sourceStatusLine: "EastMoney 代班 · Yahoo Finance 请求超时,3 分钟前自动切换",
            consecutiveFailures: 3,
            lastFailureReason: "请求超时",
            refreshInterval: 10,
            refreshOnlyInSession: true,
            marketOpen: false,
            watchlistCount: 3,
            rotationEnabled: true,
            rotationInterval: 10,
            alertCount: 2,
            triggeredAlertCount: 1,
            trendSampleCount: 42
        )
    }

    @Test("完整快照渲染出可粘贴的诊断文本")
    func rendersFullSnapshot() {
        let text = DiagnosticsReport.text(
            fullSnapshot,
            generatedAt: fixedNow,
            timeZone: TimeZone(identifier: "Asia/Shanghai")!
        )
        let lines = text.split(separator: "\n").map(String.init)

        #expect(lines.first == "StockBar diagnostics")
        #expect(text.contains("- version: 1.1.0"))
        #expect(text.contains("- generated: 2025-10-09T16:53:20+08:00"))
        #expect(text.contains("- language: zh-Hans (setting: system)"))
        #expect(text.contains("贵州茅台 1341.99 CNY, prev close 1355.30, change -13.31 (-0.98%)"))
        #expect(text.contains("- provider: selected Yahoo Finance, active EastMoney"))
        #expect(text.contains("- source: EastMoney 代班 · Yahoo Finance 请求超时,3 分钟前自动切换"))
        #expect(text.contains("- failures: 3 consecutive, last reason: 请求超时"))
        #expect(text.contains("- refresh: every 10s, session-only on, market closed"))
        #expect(text.contains("- watchlist: 3 symbols, rotation on every 10s"))
        #expect(text.contains("- alerts: 2 (1 triggered)"))
        #expect(text.contains("- trend: 42 samples"))
    }

    @Test("没有行情、没有失败时用 none 占位,且不输出 source 行")
    func rendersEmptyState() {
        let empty = DiagnosticsSnapshot(
            version: "dev",
            osVersion: "Version 15.1.0 (Build 24B83)",
            languageSetting: "en",
            language: "en",
            symbol: "AAPL",
            quote: nil,
            lastUpdated: nil,
            selectedProvider: "Yahoo Finance",
            activeProvider: "Yahoo Finance",
            sourceStatusLine: nil,
            consecutiveFailures: 0,
            lastFailureReason: nil,
            refreshInterval: 30,
            refreshOnlyInSession: false,
            marketOpen: true,
            watchlistCount: 0,
            rotationEnabled: false,
            rotationInterval: 10,
            alertCount: 0,
            triggeredAlertCount: 0,
            trendSampleCount: 0
        )
        let text = DiagnosticsReport.text(empty, generatedAt: fixedNow, timeZone: TimeZone(identifier: "UTC")!)

        #expect(text.contains("- quote: none"))
        #expect(text.contains("- last update: none"))
        #expect(text.contains("- failures: none"))
        #expect(text.contains("- refresh: every 30s, session-only off, market open"))
        #expect(text.contains("- alerts: 0 (0 triggered)"))
        #expect(!text.contains("- source:"))
        // 空状态下没有降级记录,不应出现空的 source 行
        #expect(text.split(separator: "\n").allSatisfy { !$0.hasSuffix(":") })
    }

    @Test("时间戳按传入时区渲染,便于跨时区排查")
    func rendersTimestampInGivenZone() {
        let shanghai = DiagnosticsReport.text(
            fullSnapshot,
            generatedAt: fixedNow,
            timeZone: TimeZone(identifier: "Asia/Shanghai")!
        )
        let utc = DiagnosticsReport.text(fullSnapshot, generatedAt: fixedNow, timeZone: TimeZone(identifier: "UTC")!)

        #expect(shanghai.contains("2025-10-09T16:53:20+08:00"))
        #expect(utc.contains("2025-10-09T08:53:20Z"))
    }

    @Test("版本号优先取 Info.plist,缺失时回退 dev")
    func readsVersionFromBundle() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("DiagnosticsTests-\(UUID().uuidString)", isDirectory: true)
        let bundleURL = root.appendingPathComponent("Fixture.bundle", isDirectory: true)
        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0"><dict>
            <key>CFBundleShortVersionString</key><string>9.9.9</string>
            </dict></plist>
            """
        try plist.write(to: contents.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: root) }

        let bundle = try #require(Bundle(url: bundleURL))
        #expect(DiagnosticsReport.appVersion(bundle: bundle) == "9.9.9")

        let bare = try #require(Bundle(url: root))
        #expect(DiagnosticsReport.appVersion(bundle: bare) == DiagnosticsReport.developmentVersion)
    }
}
