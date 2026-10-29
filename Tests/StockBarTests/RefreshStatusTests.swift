import Foundation
import Testing
@testable import StockBar

@Suite("RefreshStatus")
struct RefreshStatusTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private static let timeZone = TimeZone(identifier: "Asia/Shanghai")!

    private func time(_ offset: TimeInterval = 0) -> Date {
        now.addingTimeInterval(offset)
    }

    @Test("正常时不显示菜单栏图标")
    func noSymbolWhenHealthy() {
        #expect(RefreshStatus.menuBarSymbol(isFailing: false, isDegraded: false) == nil)
    }

    @Test("失败优先显示警告,降级显示循环箭头")
    func symbolPriority() {
        #expect(RefreshStatus.menuBarSymbol(isFailing: true, isDegraded: false) == "exclamationmark.triangle.fill")
        #expect(RefreshStatus.menuBarSymbol(isFailing: true, isDegraded: true) == "exclamationmark.triangle.fill")
        #expect(RefreshStatus.menuBarSymbol(isFailing: false, isDegraded: true) == "arrow.triangle.2.circlepath")
    }

    @Test("休市时说明暂停原因")
    func pausedText() {
        let text = RefreshStatus.nextRefreshText(next: time(30), now: now, isPaused: true, isFailing: false)
        #expect(text == "休市暂停自动刷新,开盘后恢复")
    }

    @Test("没有排定下次刷新时不显示")
    func noApproachingText() {
        #expect(RefreshStatus.nextRefreshText(next: nil, now: now, isPaused: false, isFailing: false) == nil)
        // 已经过期的时间也不再展示
        #expect(RefreshStatus.nextRefreshText(next: time(-10), now: now, isPaused: false, isFailing: false) == nil)
    }

    @Test("正常与失败两种措辞")
    func normalAndRetryText() {
        let next = time(45)
        let normal = RefreshStatus.nextRefreshText(next: next, now: now, isPaused: false, isFailing: false)
        let retry = RefreshStatus.nextRefreshText(next: next, now: now, isPaused: false, isFailing: true)
        #expect(normal?.hasPrefix("下次刷新 ") == true)
        #expect(retry?.hasPrefix("将在 ") == true)
        #expect(retry?.hasSuffix(" 重试") == true)
        // 两者用的是同一个时间点
        let suffix = normal?.replacingOccurrences(of: "下次刷新 ", with: "")
        #expect(retry == "将在 \(suffix ?? "") 重试")
    }

    @Test("失败摘要包含次数与原因")
    func failureSummary() {
        #expect(RefreshStatus.failureText(consecutiveFailures: 0, reason: nil) == nil)
        #expect(RefreshStatus.failureText(consecutiveFailures: 2, reason: "请求超时") == "连续失败 2 次:请求超时")
        // 没有原因词时退化为只报次数
        #expect(RefreshStatus.failureText(consecutiveFailures: 3, reason: nil) == "刷新失败 3 次")
        // 只有原因没有计数(理论上少见)时直接展示原因
        #expect(RefreshStatus.failureText(consecutiveFailures: 0, reason: "网络不可用") == "网络不可用")
    }

    @Test("时间文案使用本地时钟格式")
    func timeFormatUsesLocaleClock() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.timeZone
        // 用当天稍晚的时间点,避免跨日导致「已过期」分支
        let target = calendar.date(bySettingHour: 23, minute: 30, second: 5, of: now)!
        let text = RefreshStatus.nextRefreshText(next: target, now: now, isPaused: false, isFailing: false)
        // 具体格式随系统区域变化(24 小时制 / 12 小时制),只断言时间点被带上
        #expect(text?.hasPrefix("下次刷新 ") == true)
        #expect(text?.contains("30:05") == true)
    }
}
