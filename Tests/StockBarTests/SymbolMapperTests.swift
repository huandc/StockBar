import Testing
@testable import StockBar

@Suite("SymbolMapper")
struct SymbolMapperTests {

    @Test("带后缀的 A 股代码映射到对应市场号")
    func suffixedChinaMarkets() {
        #expect(SymbolMapper.eastMoneySecid("600519.SS") == "1.600519")
        #expect(SymbolMapper.eastMoneySecid("000001.SZ") == "0.000001")
        #expect(SymbolMapper.eastMoneySecid("832000.BJ") == "0.832000")
    }

    @Test("输入大小写与首尾空白不影响结果")
    func normalization() {
        #expect(SymbolMapper.eastMoneySecid("600519.ss") == "1.600519")
        #expect(SymbolMapper.eastMoneySecid("  aapl  ") == "105.AAPL")
        #expect(SymbolMapper.eastMoneySecid("\n700.hk\t") == "116.00700")
    }

    @Test("港股代码必须是数字,并补零到 5 位")
    func hongKongPadding() {
        #expect(SymbolMapper.eastMoneySecid("0700.HK") == "116.00700")
        #expect(SymbolMapper.eastMoneySecid("700.hk") == "116.00700")
        #expect(SymbolMapper.eastMoneySecid("116.HK") == "116.00116")
        #expect(SymbolMapper.eastMoneySecid("ABC.HK") == nil)
        #expect(SymbolMapper.eastMoneySecid(".HK") == nil)
    }

    @Test("无后缀代码按首位数字推断沪深/北交所")
    func inferredChinaMarkets() {
        #expect(SymbolMapper.eastMoneySecid("600519") == "1.600519")
        #expect(SymbolMapper.eastMoneySecid("000001") == "0.000001")
        #expect(SymbolMapper.eastMoneySecid("300750") == "0.300750")
        #expect(SymbolMapper.eastMoneySecid("430047") == "0.430047")
        #expect(SymbolMapper.eastMoneySecid("900901") == "0.900901")
        // 首位 7 不属于已知市场
        #expect(SymbolMapper.eastMoneySecid("700100") == nil)
    }

    @Test("字母开头视为美股,空输入返回 nil")
    func usMarketAndInvalid() {
        #expect(SymbolMapper.eastMoneySecid("AAPL") == "105.AAPL")
        #expect(SymbolMapper.eastMoneySecid("msft") == "105.MSFT")
        #expect(SymbolMapper.eastMoneySecid("") == nil)
        #expect(SymbolMapper.eastMoneySecid("   ") == nil)
        #expect(SymbolMapper.eastMoneySecid("600519.XX") == nil)
    }

    @Test("价格缩放位:美股/港股 3 位,其余 2 位")
    func scaleByMarket() {
        #expect(SymbolMapper.defaultScale(market: 105) == 3)
        #expect(SymbolMapper.defaultScale(market: 116) == 3)
        #expect(SymbolMapper.defaultScale(market: 0) == 2)
        #expect(SymbolMapper.defaultScale(market: 1) == 2)
        #expect(SymbolMapper.defaultScale(market: 42) == 2)
    }
}
