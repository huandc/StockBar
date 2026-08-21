import Foundation

/// 交易时段判断:按股票所属市场的本地时间判断是否处于开盘时间
/// A股/港股:北京时间(UTC+8);美股:美东时间(含夏令时,由时区自动处理)
/// 注:未包含法定节假日日历,节假日视为开盘日
enum Market: Int {
    case cn = 0   // A股(沪/深/北):09:30–11:30, 13:00–15:00
    case hk = 1   // 港股:09:30–12:00, 13:00–16:00
    case us = 2   // 美股常规时段:09:30–16:00

    var timeZone: TimeZone {
        switch self {
        case .cn: return TimeZone(identifier: "Asia/Shanghai")!
        case .hk: return TimeZone(identifier: "Asia/Hong_Kong")!
        case .us: return TimeZone(identifier: "America/New_York")!
        }
    }

    /// 交易时段区间(市场本地时间,分钟数:小时×60+分钟)
    var sessions: [ClosedRange<Int>] {
        switch self {
        case .cn: return [570...690, 780...900]   // 09:30-11:30, 13:00-15:00
        case .hk: return [570...720, 780...960]   // 09:30-12:00, 13:00-16:00
        case .us: return [570...960]              // 09:30-16:00
        }
    }

    /// 当前是否处于交易时段(周一至周五 + 时段内)
    func isOpen(at date: Date = Date()) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        guard (2...6).contains(cal.component(.weekday, from: date)) else { return false }
        let minutes = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        return sessions.contains { $0.contains(minutes) }
    }

    /// 从股票代码推断市场:A 股带 .SS/.SZ/.BJ,港股带 .HK,其余按美股
    static func detect(from symbol: String) -> Market {
        let upper = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if upper.hasSuffix(".HK") { return .hk }
        if upper.hasSuffix(".SS") || upper.hasSuffix(".SZ") || upper.hasSuffix(".BJ") { return .cn }
        return .us
    }
}
