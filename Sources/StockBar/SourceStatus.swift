import Foundation

/// 数据源健康状态:记录当前生效源、最近一次自动切换的原因、连续失败次数。
/// 纯数据结构,便于单测;由 `QuoteModel` 在刷新过程中更新。
struct SourceStatus: Equatable {
    /// 一次自动降级记录
    struct SwitchRecord: Equatable {
        let from: QuoteProvider
        let to: QuoteProvider
        /// 触发降级的用户可读原因,如「请求超时」
        let reason: String
        let at: Date
    }

    /// 用户选择的主数据源
    var selected: QuoteProvider
    /// 当前实际生效的数据源(降级期间与 selected 不同)
    var active: QuoteProvider
    /// 主源连续失败次数(成功即清零)
    var consecutiveFailures: Int = 0
    /// 最近一次自动切换记录;切回主源后保留,便于用户看到「曾经降级过」
    var lastSwitch: SwitchRecord?
    /// 最近一次成功刷新的时间
    var lastSuccessAt: Date?

    /// 连续失败多少次后切换备用源(与 `QuoteModel` 的判断阈值保持一致)
    static let failureThreshold = 2

    var isDegraded: Bool { active != selected }

    /// 设置页展示的一行状态说明
    /// - Parameter now: 当前时间,用于把切换时间写成「3 分钟前」
    func summary(now: Date = Date(), localization l10n: Localization) -> String {
        if isDegraded, let record = lastSwitch, record.to == active {
            let when = Self.relative(record.at, now: now, localization: l10n)
            return l10n.format(
                "%@ 代班 · %@ %@,%@自动切换",
                active.displayName(l10n), record.from.displayName(l10n), record.reason, when
            )
        }
        if isDegraded {
            return l10n.format("%@ 代班(%@ 不可用)", active.displayName(l10n), selected.displayName(l10n))
        }
        if consecutiveFailures > 0 {
            let remaining = max(Self.failureThreshold - consecutiveFailures, 0)
            if remaining == 0 {
                return l10n.format("%@ · 连续失败 %d 次,即将切换备用源", active.displayName(l10n), consecutiveFailures)
            }
            return l10n.format(
                "%@ · 连续失败 %d 次(再失败 %d 次切换备用源)",
                active.displayName(l10n), consecutiveFailures, remaining
            )
        }
        return l10n.format("%@ · 正常", active.displayName(l10n))
    }

    /// 后台日志用的单行状态,便于和 `log stream` 对齐
    var logLine: String {
        var parts = ["selected=\(selected.rawValue)", "active=\(active.rawValue)", "failures=\(consecutiveFailures)"]
        if let record = lastSwitch {
            parts.append("lastSwitch=\(record.from.rawValue)->\(record.to.rawValue):\(record.reason)")
        }
        return parts.joined(separator: " ")
    }

    /// 把时间点写成「刚刚 / N 分钟前 / N 小时前」,超过一天用日期
    static func relative(_ date: Date, now: Date, localization l10n: Localization) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return l10n.text("刚刚") }
        if seconds < 3600 { return l10n.format("%d 分钟前", Int(seconds / 60)) }
        if seconds < 86_400 { return l10n.format("%d 小时前", Int(seconds / 3600)) }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
