import Foundation

/// 提醒方向:上破 / 下破
enum AlertDirection: String, Codable, CaseIterable, Identifiable {
    case above
    case below

    var id: String { rawValue }

    func label(_ l10n: Localization) -> String {
        switch self {
        case .above: return l10n.text("上破")
        case .below: return l10n.text("下破")
        }
    }
}

/// 一条价格提醒:价格穿越阈值时触发,回落到阈值另一侧后自动重新武装。
struct PriceAlert: Codable, Equatable, Identifiable {
    var id: UUID
    var symbol: String
    var threshold: Double
    var direction: AlertDirection
    /// true = 已武装(等待触发);false = 已触发(等待价格回落)
    var isArmed: Bool

    init(id: UUID = UUID(), symbol: String, threshold: Double, direction: AlertDirection, isArmed: Bool = true) {
        self.id = id
        self.symbol = symbol
        self.threshold = threshold
        self.direction = direction
        self.isArmed = isArmed
    }

    /// 是否已满足触发条件(不考虑当前武装状态)
    func matches(price: Double) -> Bool {
        switch direction {
        case .above: return price >= threshold
        case .below: return price <= threshold
        }
    }

    /// 价格是否已回到阈值另一侧(可以重新武装)
    func isReleased(price: Double) -> Bool {
        switch direction {
        case .above: return price < threshold
        case .below: return price > threshold
        }
    }

    /// 面板里的一行说明,如「600519.SS 上破 1400.00 已触发」
    func line(_ l10n: Localization) -> String {
        let price = String(format: "%.2f", threshold)
        return l10n.format("%@ %@ %@ 已触发", symbol, direction.label(l10n), price)
    }
}

/// 提醒评估:纯函数,输入行情价格,输出状态变化事件
enum AlertEvaluator {
    enum Event: Equatable {
        case triggered(PriceAlert)
        case rearmed(PriceAlert)
    }

    /// 就地更新 `isArmed`,并返回本次发生的变化。
    /// - Parameter priceFor: 按代码取价格;取不到(如该代码本轮没刷新)则跳过该条提醒
    static func evaluate(_ alerts: inout [PriceAlert], priceFor: (String) -> Double?) -> [Event] {
        var events: [Event] = []
        for index in alerts.indices {
            guard let price = priceFor(alerts[index].symbol) else { continue }
            if alerts[index].isArmed, alerts[index].matches(price: price) {
                alerts[index].isArmed = false
                events.append(.triggered(alerts[index]))
            } else if !alerts[index].isArmed, alerts[index].isReleased(price: price) {
                alerts[index].isArmed = true
                events.append(.rearmed(alerts[index]))
            }
        }
        return events
    }
}
