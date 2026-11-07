import Foundation

/// 刷新状态的展示文案(纯函数,便于单测)
enum RefreshStatus {
    /// 菜单栏上的异常/降级图标;正常时返回 nil
    static func menuBarSymbol(isFailing: Bool, isDegraded: Bool) -> String? {
        if isFailing { return "exclamationmark.triangle.fill" }
        if isDegraded { return "arrow.triangle.2.circlepath" }
        return nil
    }

    /// 面板底部的刷新计划说明
    /// - Parameters:
    ///   - next: 下一次自动刷新的时间;nil 表示没有排定(如未开启定时)
    ///   - now: 当前时间,用于避免显示已过期的时间
    ///   - isPaused: 「仅交易时段自动刷新」且当前休市
    ///   - isFailing: 上一次刷新失败
    static func nextRefreshText(
        next: Date?, now: Date, isPaused: Bool, isFailing: Bool, localization l10n: Localization
    ) -> String? {
        if isPaused { return l10n.text("休市暂停自动刷新,开盘后恢复") }
        guard let next, next > now else { return nil }
        let time = next.formatted(date: .omitted, time: .standard)
        return isFailing ? l10n.format("将在 %@ 重试", time) : l10n.format("下次刷新 %@", time)
    }

    /// 失败提示:连续失败次数 + 最近一次原因(两者都没有时返回 nil)
    static func failureText(
        consecutiveFailures: Int, reason: String?, localization l10n: Localization
    ) -> String? {
        guard consecutiveFailures > 0 else { return reason }
        guard let reason else { return l10n.format("刷新失败 %d 次", consecutiveFailures) }
        return l10n.format("连续失败 %d 次:%@", consecutiveFailures, reason)
    }
}
