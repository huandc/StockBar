import Foundation

/// 自选列表与菜单栏轮显的纯逻辑(便于单测)
enum WatchlistRotation {
    /// 自选列表最多参与的符号数(菜单栏轮显时每个 tick 都要拉一次行情,不宜过大)
    static let maxSymbols = 12

    /// 解析用户输入:`AAPL, 0700.HK` 或换行分隔;统一大写、去重、去掉空项并限制数量
    static func normalize(_ raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",，;；、\n\r\t")
        var seen = Set<String>()
        var result: [String] = []
        for part in raw.components(separatedBy: separators) {
            let symbol = part.trimmingCharacters(in: .whitespaces).uppercased()
            guard !symbol.isEmpty, !seen.contains(symbol) else { continue }
            seen.insert(symbol)
            result.append(symbol)
        }
        return Array(result.prefix(maxSymbols))
    }

    /// 回写给输入框的文本形式
    static func join(_ symbols: [String]) -> String {
        symbols.joined(separator: ", ")
    }

    /// 菜单栏实际轮显的符号列表
    /// - Returns: 开启轮显且至少两个符号时返回自选列表;否则返回空数组,表示沿用单符号模式
    static func rotationSymbols(watchlist: [String], enabled: Bool) -> [String] {
        guard enabled else { return [] }
        return watchlist.count > 1 ? Array(watchlist.prefix(maxSymbols)) : []
    }

    /// 下一个轮显下标(到达末尾回到开头)
    static func nextIndex(after index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index % count) + 1) % count
    }

    /// 把下标收敛到合法范围(自选列表增删后可能越界)
    static func clampIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(index, 0), count - 1)
    }
}
