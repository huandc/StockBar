import Testing
@testable import StockBar

@Suite("DisplayFormat")
struct DisplayFormatTests {

    @Test("模板占位符全部替换,价格两位小数、涨跌带符号")
    func renderAllPlaceholders() {
        let text = MenuBarTemplate.render(
            template: "{code} {name} {price} {change} {changePercent}",
            code: "600519.SS",
            name: "贵州茅台",
            price: 1680.456,
            change: 12.345,
            changePercent: 0.74
        )
        #expect(text == "600519.SS 贵州茅台 1680.46 +12.35 +0.74%")
    }

    @Test("负涨跌与四舍五入保留符号")
    func negativeAndRounding() {
        let text = MenuBarTemplate.render(
            template: "{price}|{change}|{changePercent}",
            code: "AAPL",
            name: nil,
            price: 0.005,
            change: -0.004,
            changePercent: -1.005
        )
        #expect(text == "0.01|-0.00|-1.00%")
    }

    @Test("名称为空时回退为代码")
    func nameFallsBackToCode() {
        let text = MenuBarTemplate.render(
            template: "{name}",
            code: "0700.HK",
            name: nil,
            price: 100,
            change: 0,
            changePercent: 0
        )
        #expect(text == "0700.HK")
    }

    @Test("未知占位符保持原样")
    func unknownPlaceholderUntouched() {
        let text = MenuBarTemplate.render(
            template: "{foo} {price}",
            code: "AAPL",
            name: nil,
            price: 1,
            change: 0,
            changePercent: 0
        )
        #expect(text == "{foo} 1.00")
    }

    @Test("菜单栏格式枚举完整且标签非空")
    func menuBarFormats() {
        #expect(MenuBarFormat.allCases.count == 4)
        #expect(MenuBarFormat.allCases.map(\.id) == ["price", "codePrice", "namePrice", "custom"])
        #expect(MenuBarFormat.allCases.allSatisfy { !$0.label.isEmpty })
    }
}
