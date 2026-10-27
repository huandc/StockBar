import Foundation
import Testing
@testable import StockBar

@Suite("SourceStatus")
struct SourceStatusTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func date(secondsAgo: TimeInterval) -> Date {
        now.addingTimeInterval(-secondsAgo)
    }

    @Test("未降级且无失败时显示正常")
    func healthySummary() {
        let status = SourceStatus(selected: .yahoo, active: .yahoo)
        #expect(!status.isDegraded)
        #expect(status.summary(now: now) == "Yahoo Finance · 正常")
    }

    @Test("降级后说明谁代班、原因与切换时间")
    func degradedSummary() {
        var status = SourceStatus(selected: .yahoo, active: .eastmoney)
        status.lastSwitch = SourceStatus.SwitchRecord(
            from: .yahoo,
            to: .eastmoney,
            reason: "请求超时",
            at: date(secondsAgo: 180)
        )
        #expect(status.isDegraded)
        #expect(status.summary(now: now) == "东方财富 代班 · Yahoo Finance 请求超时,3 分钟前自动切换")
    }

    @Test("有一天的旧切换记录时显示具体日期")
    func degradedSummaryWithDate() {
        var status = SourceStatus(selected: .yahoo, active: .eastmoney)
        status.lastSwitch = SourceStatus.SwitchRecord(
            from: .yahoo,
            to: .eastmoney,
            reason: "网络不可用",
            at: date(secondsAgo: 2 * 86_400)
        )
        #expect(status.summary(now: now).contains("自动切换"))
        #expect(status.summary(now: now).contains("网络不可用"))
    }

    @Test("失败计数提示还需几次才切换")
    func failureSummary() {
        var status = SourceStatus(selected: .yahoo, active: .yahoo)
        status.consecutiveFailures = 1
        #expect(status.summary(now: now) == "Yahoo Finance · 连续失败 1 次(再失败 1 次切换备用源)")

        status.consecutiveFailures = SourceStatus.failureThreshold
        #expect(status.summary(now: now).contains("即将切换备用源"))
    }

    @Test("切回主源后保留最近一次切换记录用于回溯")
    func keepsLastSwitchAfterRecovery() {
        var status = SourceStatus(selected: .yahoo, active: .eastmoney)
        status.lastSwitch = SourceStatus.SwitchRecord(from: .yahoo, to: .eastmoney, reason: "请求超时", at: now)
        status.active = .yahoo
        #expect(!status.isDegraded)
        #expect(status.lastSwitch?.to == .eastmoney)
        #expect(status.summary(now: now) == "Yahoo Finance · 正常")
    }

    @Test("日志行包含主源、生效源与失败次数")
    func logLine() {
        var status = SourceStatus(selected: .eastmoney, active: .yahoo)
        status.consecutiveFailures = 2
        status.lastSwitch = SourceStatus.SwitchRecord(from: .eastmoney, to: .yahoo, reason: "请求超时", at: now)
        let line = status.logLine
        #expect(line.contains("selected=eastmoney"))
        #expect(line.contains("active=yahoo"))
        #expect(line.contains("failures=2"))
        #expect(line.contains("eastmoney->yahoo:请求超时"))
    }

    @Test("相对时间:刚刚 / 分钟 / 小时 / 日期")
    func relativeTime() {
        #expect(SourceStatus.relative(date(secondsAgo: 10), now: now) == "刚刚")
        #expect(SourceStatus.relative(date(secondsAgo: 120), now: now) == "2 分钟前")
        #expect(SourceStatus.relative(date(secondsAgo: 3 * 3600), now: now) == "3 小时前")
        let old = SourceStatus.relative(date(secondsAgo: 5 * 86_400), now: now)
        #expect(old.count == 11) // MM-dd HH:mm
    }

    @Test("错误原因映射成用户能看懂的一句短话")
    func userFacingReasons() {
        #expect(FetchError.timeout.userFacingReason == "请求超时")
        #expect(FetchError.network("x").userFacingReason == "网络不可用")
        #expect(FetchError.http(429).userFacingReason == "请求过于频繁")
        #expect(FetchError.http(503).userFacingReason == "服务端错误 503")
        #expect(FetchError.http(404).userFacingReason == "HTTP 404")
        #expect(FetchError.api("bad").userFacingReason == "接口返回异常")
        #expect(FetchError.noData.userFacingReason == "无有效行情数据")
    }
}
