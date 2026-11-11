import Foundation

/// 一份可直接粘贴进 Issue 的运行时诊断快照。
///
/// 设计成纯数据 + 纯函数:不读全局状态、不碰 AppKit,便于在测试里构造边界场景
/// (没有行情、没有失败记录、休市中)。
struct DiagnosticsSnapshot: Equatable {
    var version: String
    var osVersion: String
    /// 语言设置项本身(可能仍是「跟随系统」)
    var languageSetting: String
    /// 解析后的实际语言,如 `zh-Hans`
    var language: String
    var symbol: String
    var quote: Quote?
    var lastUpdated: Date?
    var selectedProvider: String
    var activeProvider: String
    /// 数据源状态行(降级时才有内容)
    var sourceStatusLine: String?
    var consecutiveFailures: Int
    var lastFailureReason: String?
    var refreshInterval: Int
    var refreshOnlyInSession: Bool
    var marketOpen: Bool
    var watchlistCount: Int
    var rotationEnabled: Bool
    var rotationInterval: Int
    var alertCount: Int
    var triggeredAlertCount: Int
    var trendSampleCount: Int
}

/// 把 `DiagnosticsSnapshot` 渲染成多行纯文本。
///
/// 标签统一用英文:这份文本是给维护者看的,常常直接贴到英文 Issue 里;
/// 值则保留用户当前的界面语言。时间一律用 ISO 8601(带显式时区偏移),
/// 避免「21:10:03」这种跨时区读不懂的写法。
enum DiagnosticsReport {
    /// 版本号来自打包时写入的 `CFBundleShortVersionString`;本地 `swift run` 时没有该键
    static let versionKey = "CFBundleShortVersionString"
    static let developmentVersion = "dev"

    static func appVersion(bundle: Bundle = .main) -> String {
        (bundle.object(forInfoDictionaryKey: versionKey) as? String) ?? developmentVersion
    }

    static func text(
        _ snapshot: DiagnosticsSnapshot,
        generatedAt: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        let iso = isoFormatter(timeZone: timeZone)
        var lines: [String] = [
            "StockBar diagnostics",
            "- version: \(snapshot.version)",
            "- macOS: \(snapshot.osVersion)",
            "- generated: \(iso.string(from: generatedAt))",
            "- language: \(snapshot.language) (setting: \(snapshot.languageSetting))",
            "- symbol: \(snapshot.symbol)",
            "- quote: \(quoteLine(snapshot.quote, timeZone: timeZone))",
            "- last update: \(snapshot.lastUpdated.map { iso.string(from: $0) } ?? "none")",
            "- provider: selected \(snapshot.selectedProvider), active \(snapshot.activeProvider)",
        ]
        if let sourceLine = snapshot.sourceStatusLine, !sourceLine.isEmpty {
            lines.append("- source: \(sourceLine)")
        }
        lines.append("- failures: \(failureLine(snapshot))")
        lines.append(
            "- refresh: every \(snapshot.refreshInterval)s, session-only \(onOff(snapshot.refreshOnlyInSession)), market \(snapshot.marketOpen ? "open" : "closed")"
        )
        lines.append(
            "- watchlist: \(snapshot.watchlistCount) symbols, rotation \(snapshot.rotationEnabled ? "on" : "off") every \(snapshot.rotationInterval)s"
        )
        lines.append("- alerts: \(snapshot.alertCount) (\(snapshot.triggeredAlertCount) triggered)")
        lines.append("- trend: \(snapshot.trendSampleCount) samples")
        return lines.joined(separator: "\n")
    }

    private static func quoteLine(_ quote: Quote?, timeZone: TimeZone) -> String {
        guard let quote else { return "none" }
        let price = String(format: "%.2f", quote.price)
        let previous = String(format: "%.2f", quote.previousClose)
        let change = String(format: "%.2f", quote.change)
        let percent = String(format: "%.2f%%", quote.changePercent)
        let name = quote.name.flatMap { $0.isEmpty ? nil : $0 } ?? "unnamed"
        let marketTime = quote.marketTime.map { isoFormatter(timeZone: timeZone).string(from: $0) } ?? "none"
        return
            "\(name) \(price) \(quote.currency), prev close \(previous), change \(change) (\(percent)), market time \(marketTime)"
    }

    private static func failureLine(_ snapshot: DiagnosticsSnapshot) -> String {
        guard snapshot.consecutiveFailures > 0 else { return "none" }
        let reason = snapshot.lastFailureReason ?? "unknown"
        return "\(snapshot.consecutiveFailures) consecutive, last reason: \(reason)"
    }

    private static func onOff(_ value: Bool) -> String { value ? "on" : "off" }

    private static func isoFormatter(timeZone: TimeZone) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = timeZone
        return formatter
    }
}
