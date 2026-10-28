import Foundation
import Testing
@testable import StockBar

@Suite("MenuBarLayout")
struct MenuBarLayoutTests {

    /// 每个字符固定 10pt 的假测量函数,便于断言精确结果
    private let measure: (String) -> Double = { Double($0.count) * 10 }

    @Test("未超宽时原样返回")
    func keepsShortText() {
        #expect(MenuBarLayout.fittingText("AAPL 190.50", maxWidth: 200, measure: measure) == "AAPL 190.50")
    }

    @Test("宽度为 0 表示不限制")
    func unlimitedKeepsEverything() {
        let long = String(repeating: "A", count: 100)
        #expect(MenuBarLayout.fittingText(long, maxWidth: 0, measure: measure) == long)
    }

    @Test("超宽时从开头截断,保留尾部的数值")
    func truncatesHeadKeepsTail() {
        let text = "贵州茅台 1234.56"   // 11 字符 = 110pt
        let fitted = MenuBarLayout.fittingText(text, maxWidth: 80, measure: measure)
        #expect(fitted.hasPrefix("…"))
        #expect(fitted == "…1234.56")
        #expect(measure(fitted) <= 80)
    }

    @Test("结果宽度始终不超过上限")
    func neverExceedsMaxWidth() {
        let text = "VeryLongCompanyName 1234567.89"
        for limit in stride(from: 40.0, through: 200.0, by: 10.0) {
            let fitted = MenuBarLayout.fittingText(text, maxWidth: limit, measure: measure)
            #expect(measure(fitted) <= limit)
        }
    }

    @Test("上限小到放不下省略号时退化为单个省略号")
    func degradesToEllipsis() {
        #expect(MenuBarLayout.fittingText("AAPL 190.50", maxWidth: 5, measure: measure) == "…")
    }

    @Test("裁剪保持幂等:已适配的文本再次裁剪不变")
    func idempotent() {
        let text = "贵州茅台 1234.56"
        let once = MenuBarLayout.fittingText(text, maxWidth: 80, measure: measure)
        #expect(MenuBarLayout.fittingText(once, maxWidth: 80, measure: measure) == once)
    }

    @Test("默认宽度与可调范围合理")
    func defaults() {
        #expect(MenuBarLayout.defaultMaxWidth == 200)
        #expect(MenuBarLayout.widthRange.contains(MenuBarLayout.defaultMaxWidth))
        #expect(MenuBarLayout.unlimited == 0)
    }

    @Test("真实字体测量的宽度随字符数增长")
    func realMeasurementGrowsWithText() {
        let short = MenuBarLayout.textWidth("AAPL")
        let long = MenuBarLayout.textWidth("AAPL 190.50 (+1.23%)")
        #expect(short > 0)
        #expect(long > short)
        // 真实测量与裁剪配合后也不超限
        let fitted = MenuBarLayout.fittingText("贵州茅台 1234.56 (+1.23%)", maxWidth: 120)
        #expect(MenuBarLayout.textWidth(fitted) <= 120)
    }
}
