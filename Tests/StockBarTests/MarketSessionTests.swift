import Foundation
import Testing
@testable import StockBar

/// 在指定市场本地时区构造时刻,避免测试依赖机器时区
private func localDate(
    _ year: Int, _ month: Int, _ day: Int,
    _ hour: Int, _ minute: Int,
    in timeZone: TimeZone
) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    return calendar.date(from: components)!
}

@Suite("MarketSession")
struct MarketSessionTests {

    private let cn = Market.cn.timeZone
    private let hk = Market.hk.timeZone
    private let us = Market.us.timeZone

    @Test("A 股:上午/下午开盘,午休与收盘后不开盘")
    func chinaSessions() {
        // 2026-10-23 是周五
        #expect(Market.cn.isOpen(at: localDate(2026, 10, 23, 10, 0, in: cn)))
        #expect(Market.cn.isOpen(at: localDate(2026, 10, 23, 13, 0, in: cn)))
        #expect(Market.cn.isOpen(at: localDate(2026, 10, 23, 15, 0, in: cn)))
        #expect(!Market.cn.isOpen(at: localDate(2026, 10, 23, 9, 29, in: cn)))
        #expect(!Market.cn.isOpen(at: localDate(2026, 10, 23, 11, 31, in: cn)))
        #expect(!Market.cn.isOpen(at: localDate(2026, 10, 23, 12, 0, in: cn)))
        #expect(!Market.cn.isOpen(at: localDate(2026, 10, 23, 12, 59, in: cn)))
        #expect(!Market.cn.isOpen(at: localDate(2026, 10, 23, 15, 1, in: cn)))
    }

    @Test("港股:午休 12:00 收,13:00 开,16:00 收")
    func hongKongSessions() {
        #expect(Market.hk.isOpen(at: localDate(2026, 10, 23, 9, 30, in: hk)))
        #expect(Market.hk.isOpen(at: localDate(2026, 10, 23, 12, 0, in: hk)))
        #expect(!Market.hk.isOpen(at: localDate(2026, 10, 23, 12, 1, in: hk)))
        #expect(Market.hk.isOpen(at: localDate(2026, 10, 23, 15, 59, in: hk)))
        #expect(!Market.hk.isOpen(at: localDate(2026, 10, 23, 16, 1, in: hk)))
    }

    @Test("美股:按纽约时间 09:30–16:00 判定")
    func usSessions() {
        #expect(Market.us.isOpen(at: localDate(2026, 10, 23, 9, 30, in: us)))
        #expect(Market.us.isOpen(at: localDate(2026, 10, 23, 12, 0, in: us)))
        #expect(Market.us.isOpen(at: localDate(2026, 10, 23, 16, 0, in: us)))
        #expect(!Market.us.isOpen(at: localDate(2026, 10, 23, 9, 29, in: us)))
        #expect(!Market.us.isOpen(at: localDate(2026, 10, 23, 16, 1, in: us)))
    }

    @Test("周末即使处于时段内也不开盘")
    func weekendsClosed() {
        // 2026-10-24 周六,2026-10-25 周日
        #expect(!Market.cn.isOpen(at: localDate(2026, 10, 24, 10, 0, in: cn)))
        #expect(!Market.hk.isOpen(at: localDate(2026, 10, 25, 10, 0, in: hk)))
        #expect(!Market.us.isOpen(at: localDate(2026, 10, 24, 12, 0, in: us)))
    }

    @Test("自定义时段覆盖默认时段,空数组回退默认")
    func customSessions() {
        let night = [SessionRange(startMinute: 20 * 60, endMinute: 23 * 60)]
        let friday = localDate(2026, 10, 23, 21, 0, in: cn)

        #expect(Market.cn.isOpen(at: friday, customSessions: night))
        // 同一时刻默认时段已收盘
        #expect(!Market.cn.isOpen(at: friday))
        // 空自定义数组视为未配置,回退默认时段
        #expect(!Market.cn.isOpen(at: friday, customSessions: []))
        // 自定义时段仍受周末限制
        #expect(!Market.cn.isOpen(at: localDate(2026, 10, 24, 21, 0, in: cn), customSessions: night))
    }

    @Test("默认时段与代码注释中的时段一致")
    func defaultRanges() {
        #expect(Market.cn.defaultSessionRanges == [
            SessionRange(startMinute: 570, endMinute: 690),
            SessionRange(startMinute: 780, endMinute: 900)
        ])
        #expect(Market.hk.defaultSessionRanges == [
            SessionRange(startMinute: 570, endMinute: 720),
            SessionRange(startMinute: 780, endMinute: 960)
        ])
        #expect(Market.us.defaultSessionRanges == [
            SessionRange(startMinute: 570, endMinute: 960)
        ])
    }

    @Test("从代码后缀识别市场,大小写与空白不敏感")
    func detectMarket() {
        #expect(Market.detect(from: "600519.SS") == .cn)
        #expect(Market.detect(from: "000001.sz") == .cn)
        #expect(Market.detect(from: "832000.BJ") == .cn)
        #expect(Market.detect(from: "0700.HK") == .hk)
        #expect(Market.detect(from: " 0700.hk ") == .hk)
        #expect(Market.detect(from: "AAPL") == .us)
        #expect(Market.detect(from: "") == .us)
    }
}
