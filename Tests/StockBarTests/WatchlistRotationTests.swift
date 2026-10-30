import Foundation
import Testing
@testable import StockBar

@Suite("WatchlistRotation")
struct WatchlistRotationTests {

    @Test("英文逗号分隔、统一大写并去重")
    func normalizeBasic() {
        let list = WatchlistRotation.normalize("aapl, 0700.hk, MSFT , msft")
        #expect(list == ["AAPL", "0700.HK", "MSFT"])
    }

    @Test("中文逗号、分号与换行都可作为分隔符")
    func normalizeSeparators() {
        let raw = "AAPL，TSLA；NVDA\nBABA、0700.HK"
        #expect(WatchlistRotation.normalize(raw) == ["AAPL", "TSLA", "NVDA", "BABA", "0700.HK"])
    }

    @Test("空输入与纯分隔符返回空列表")
    func normalizeEmpty() {
        #expect(WatchlistRotation.normalize("").isEmpty)
        #expect(WatchlistRotation.normalize(" , ，\n ").isEmpty)
    }

    @Test("数量超过上限时截断")
    func normalizeCapsCount() {
        let raw = (1...20).map { "S\($0)" }.joined(separator: ",")
        let list = WatchlistRotation.normalize(raw)
        #expect(list.count == WatchlistRotation.maxSymbols)
        #expect(list.first == "S1")
        #expect(list.last == "S\(WatchlistRotation.maxSymbols)")
    }

    @Test("回写文本可被再次解析")
    func joinRoundTrip() {
        let symbols = ["AAPL", "0700.HK", "MSFT"]
        #expect(WatchlistRotation.normalize(WatchlistRotation.join(symbols)) == symbols)
    }

    @Test("关闭轮显或只有一个符号时不轮显")
    func rotationSymbolsGate() {
        #expect(WatchlistRotation.rotationSymbols(watchlist: ["AAPL", "MSFT"], enabled: false).isEmpty)
        #expect(WatchlistRotation.rotationSymbols(watchlist: ["AAPL"], enabled: true).isEmpty)
        #expect(WatchlistRotation.rotationSymbols(watchlist: [], enabled: true).isEmpty)
        #expect(WatchlistRotation.rotationSymbols(watchlist: ["AAPL", "MSFT"], enabled: true) == ["AAPL", "MSFT"])
    }

    @Test("下标循环推进")
    func nextIndexWraps() {
        #expect(WatchlistRotation.nextIndex(after: 0, count: 3) == 1)
        #expect(WatchlistRotation.nextIndex(after: 2, count: 3) == 0)
        #expect(WatchlistRotation.nextIndex(after: 5, count: 3) == 0)
        #expect(WatchlistRotation.nextIndex(after: 0, count: 0) == 0)
    }

    @Test("越界下标被收敛到合法范围")
    func clampIndex() {
        #expect(WatchlistRotation.clampIndex(9, count: 3) == 2)
        #expect(WatchlistRotation.clampIndex(-2, count: 3) == 0)
        #expect(WatchlistRotation.clampIndex(1, count: 3) == 1)
        #expect(WatchlistRotation.clampIndex(4, count: 0) == 0)
    }
}
