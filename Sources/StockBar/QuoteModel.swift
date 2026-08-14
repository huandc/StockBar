import SwiftUI
import AppKit

/// 全局数据模型:持有最新行情、设置项,并负责定时刷新
@MainActor
final class QuoteModel: ObservableObject {
    // MARK: 行情状态

    @Published private(set) var quote: Quote?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?

    // MARK: 设置(自动持久化到 UserDefaults)

    @Published var symbol: String {
        didSet {
            UserDefaults.standard.set(symbol, forKey: "symbol")
            restartTimer()
            Task { await refresh() }
        }
    }

    @Published var refreshInterval: Int {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
            restartTimer()
        }
    }

    /// 中国习惯:红涨绿跌(默认 false,即绿涨红跌)
    @Published var redUpGreenDown: Bool {
        didSet {
            UserDefaults.standard.set(redUpGreenDown, forKey: "redUpGreenDown")
        }
    }

    private var timer: Timer?

    init() {
        let defaults = UserDefaults.standard
        symbol = defaults.string(forKey: "symbol") ?? "AAPL"
        refreshInterval = defaults.object(forKey: "refreshInterval") as? Int ?? 10
        redUpGreenDown = defaults.bool(forKey: "redUpGreenDown")
        restartTimer()
    }

    // MARK: 刷新

    func refresh() async {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "请输入股票代码"
            return
        }
        do {
            quote = try await StockFetcher.fetch(symbol: trimmed)
            errorMessage = nil
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = max(3, refreshInterval)
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.startRefresh()
            }
        }
    }

    /// 供 UI 调用的无返回值刷新入口
    func startRefresh() {
        Task { await refresh() }
    }

    // MARK: 展示

    var menuBarText: String {
        let code = symbol.uppercased()
        if let q = quote {
            return "\(code) \(String(format: "%.2f", q.price))"
        }
        return "\(code) --"
    }

    var menuBarColor: Color {
        guard let q = quote else { return .secondary }
        return changeColor(q)
    }

    func changeColor(_ q: Quote) -> Color {
        if q.change > 0 {
            return redUpGreenDown ? .red : .green
        } else if q.change < 0 {
            return redUpGreenDown ? .green : .red
        }
        return .secondary
    }

    /// 带符号的涨跌幅文本,如 "+1.23 (+0.52%)"
    func changeText(_ q: Quote) -> String {
        let sign = q.change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", q.change))  (\(sign)\(String(format: "%.2f", q.changePercent))%)"
    }
}
