import Foundation
import Testing

@testable import StockBar

struct PriceAlertTests {
    private func alert(_ direction: AlertDirection, _ threshold: Double, armed: Bool = true) -> PriceAlert {
        PriceAlert(symbol: "600519.SS", threshold: threshold, direction: direction, isArmed: armed)
    }

    @Test("上破:达到阈值触发一次,继续上涨不重复触发")
    func triggersAboveOnce() {
        var alerts = [alert(.above, 1400)]
        let first = AlertEvaluator.evaluate(&alerts) { _ in 1400 }
        #expect(first == [.triggered(alerts[0])])
        #expect(alerts[0].isArmed == false)

        let second = AlertEvaluator.evaluate(&alerts) { _ in 1450 }
        #expect(second.isEmpty)
        #expect(alerts[0].isArmed == false)
    }

    @Test("上破:回落到阈值下方后重新武装,再次上破可再触发")
    func rearmsAbove() {
        var alerts = [alert(.above, 1400, armed: false)]
        let released = AlertEvaluator.evaluate(&alerts) { _ in 1399.99 }
        #expect(released == [.rearmed(alerts[0])])
        #expect(alerts[0].isArmed)

        let again = AlertEvaluator.evaluate(&alerts) { _ in 1400.01 }
        #expect(again == [.triggered(alerts[0])])
    }

    @Test("下破:低于阈值触发,高于阈值复位")
    func triggersBelow() {
        var alerts = [alert(.below, 1200)]
        #expect(AlertEvaluator.evaluate(&alerts) { _ in 1250 }.isEmpty)
        #expect(AlertEvaluator.evaluate(&alerts) { _ in 1200 } == [.triggered(alerts[0])])
        #expect(AlertEvaluator.evaluate(&alerts) { _ in 1200 }.isEmpty)
        #expect(AlertEvaluator.evaluate(&alerts) { _ in 1205 } == [.rearmed(alerts[0])])
    }

    @Test("取不到价格的代码被跳过")
    func skipsUnknownSymbol() {
        var alerts = [alert(.above, 1400)]
        let events = AlertEvaluator.evaluate(&alerts) { _ in nil }
        #expect(events.isEmpty)
        #expect(alerts[0].isArmed)
    }

    @Test("多条提醒互不影响")
    func multipleAlerts() {
        var alerts = [
            PriceAlert(symbol: "AAPL", threshold: 200, direction: .above),
            PriceAlert(symbol: "600519.SS", threshold: 1200, direction: .below),
        ]
        let prices = ["AAPL": 201.0, "600519.SS": 1250.0]
        let events = AlertEvaluator.evaluate(&alerts) { prices[$0] }
        #expect(events == [.triggered(alerts[0])])
        #expect(alerts[0].isArmed == false)
        #expect(alerts[1].isArmed)
    }

    @Test("编解码往返后状态完整")
    func codableRoundTrip() throws {
        let original = [
            PriceAlert(symbol: "AAPL", threshold: 190.5, direction: .above),
            PriceAlert(symbol: "0700.HK", threshold: 300, direction: .below, isArmed: false),
        ]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([PriceAlert].self, from: data)
        #expect(decoded == original)
    }

    @Test("面板文案随语言变化")
    func localizedLine() {
        let above = PriceAlert(symbol: "600519.SS", threshold: 1400, direction: .above)
        #expect(above.line(.chinese) == "600519.SS 上破 1400.00 已触发")
        #expect(above.line(.english) == "600519.SS Crosses above 1400.00 triggered")
        let below = PriceAlert(symbol: "AAPL", threshold: 180, direction: .below)
        #expect(below.direction.label(.english) == "Crosses below")
    }
}
