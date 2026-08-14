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
            recordHistory(symbol)
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

    /// 配色方案(默认国际:绿涨红跌;旧版「红涨绿跌」开关自动迁移)
    @Published var colorPreset: ColorPreset {
        didSet {
            UserDefaults.standard.set(colorPreset.rawValue, forKey: "colorPreset")
        }
    }

    /// 自定义涨色(默认绿 #22C55E)
    @Published var upColor: Color {
        didSet { persistColor(upColor, forKey: "upColorRGB") }
    }

    /// 自定义跌色(默认红 #EF4444)
    @Published var downColor: Color {
        didSet { persistColor(downColor, forKey: "downColorRGB") }
    }

    /// 自定义平盘色(默认灰 #9CA3AF)
    @Published var flatColor: Color {
        didSet { persistColor(flatColor, forKey: "flatColorRGB") }
    }

    /// 数据源(默认 Yahoo Finance)
    @Published var selectedProvider: QuoteProvider {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "dataSource")
            activeProvider = selectedProvider // 用户切换数据源时重置当前生效源
            restartTimer()
            Task { await refresh() }
        }
    }

    /// 主源失败自动切换备用源(默认开启)
    @Published var enableFallback: Bool {
        didSet {
            UserDefaults.standard.set(enableFallback, forKey: "enableFallback")
        }
    }

    /// 当前实际生效的数据源(开启降级后可能与 selectedProvider 不同)
    @Published private(set) var activeProvider: QuoteProvider

    /// 菜单栏显示格式(默认代码 + 价格,保持现状)
    @Published var menuBarFormat: MenuBarFormat {
        didSet {
            UserDefaults.standard.set(menuBarFormat.rawValue, forKey: "menuBarFormat")
        }
    }

    /// 自定义模板(仅 menuBarFormat == .custom 生效)
    @Published var menuBarTemplate: String {
        didSet {
            UserDefaults.standard.set(menuBarTemplate, forKey: "menuBarTemplate")
        }
    }

    /// 自定义显示名,留空使用接口返回的名称
    @Published var displayName: String {
        didSet {
            UserDefaults.standard.set(displayName, forKey: "displayName")
        }
    }

    /// 最近输入的股票代码(供设置面板快捷选择),最新的在最前
    @Published private(set) var symbolHistory: [String]

    private static let maxHistoryCount = 10
    private var timer: Timer?
    private var consecutiveFailures = 0

    init() {
        let defaults = UserDefaults.standard
        symbol = defaults.string(forKey: "symbol") ?? "AAPL"
        symbolHistory = defaults.stringArray(forKey: "symbolHistory") ?? []
        refreshInterval = defaults.object(forKey: "refreshInterval") as? Int ?? 10
        let provider = QuoteProvider(rawValue: defaults.string(forKey: "dataSource") ?? "") ?? .yahoo
        selectedProvider = provider
        activeProvider = provider
        enableFallback = defaults.object(forKey: "enableFallback") as? Bool ?? true
        menuBarFormat = MenuBarFormat(rawValue: defaults.string(forKey: "menuBarFormat") ?? "") ?? .codePrice
        menuBarTemplate = defaults.string(forKey: "menuBarTemplate") ?? ""
        displayName = defaults.string(forKey: "displayName") ?? ""
        // 配色:新键 colorPreset 优先;老用户按旧开关 redUpGreenDown 迁移
        if let presetRaw = defaults.string(forKey: "colorPreset") {
            colorPreset = ColorPreset(rawValue: presetRaw) ?? .international
        } else {
            colorPreset = defaults.bool(forKey: "redUpGreenDown") ? .chinese : .international
        }
        upColor = RGBColor.decode(defaults.data(forKey: "upColorRGB") ?? Data())?.color ?? ColorPreset.defaultUp
        downColor = RGBColor.decode(defaults.data(forKey: "downColorRGB") ?? Data())?.color ?? ColorPreset.defaultDown
        flatColor = RGBColor.decode(defaults.data(forKey: "flatColorRGB") ?? Data())?.color ?? ColorPreset.defaultFlat
        restartTimer()
    }

    private func persistColor(_ color: Color, forKey key: String) {
        UserDefaults.standard.set(color.rgb?.encodeData(), forKey: key)
    }

    /// 记录股票代码到历史(去重、最新在前、最多 10 条)
    func recordHistory(_ symbol: String) {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let upper = trimmed.uppercased()
        var list = symbolHistory.filter { $0.uppercased() != upper }
        list.insert(upper, at: 0)
        if list.count > Self.maxHistoryCount {
            list = Array(list.prefix(Self.maxHistoryCount))
        }
        symbolHistory = list
        UserDefaults.standard.set(list, forKey: "symbolHistory")
    }

    // MARK: 刷新

    func refresh() async {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "请输入股票代码"
            return
        }
        do {
            quote = try await fetchWithFallback(trimmed)
            errorMessage = nil
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 优先用所选数据源;连续失败 2 次自动切到备用源;降级期间每轮尝试恢复所选源
    private func fetchWithFallback(_ symbol: String) async throws -> Quote {
        // 降级状态:每轮先尝试所选源,成功即切回;失败继续用备用源
        if activeProvider != selectedProvider {
            do {
                let q = try await selectedProvider.provider.fetch(symbol: symbol)
                activeProvider = selectedProvider
                consecutiveFailures = 0
                return q
            } catch {
                return try await activeProvider.provider.fetch(symbol: symbol)
            }
        }

        do {
            let q = try await activeProvider.provider.fetch(symbol: symbol)
            consecutiveFailures = 0
            return q
        } catch {
            guard enableFallback else { throw error }
            consecutiveFailures += 1
            guard consecutiveFailures >= 2 else { throw error }
            consecutiveFailures = 0
            let backup: QuoteProvider = activeProvider == .yahoo ? .eastmoney : .yahoo
            activeProvider = backup
            return try await backup.provider.fetch(symbol: symbol)
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

    /// 显示名:自定义别名优先,其次接口名称,最后回退代码
    var resolvedName: String? {
        let custom = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return quote?.name
    }

    var menuBarText: String {
        let code = symbol.uppercased()
        guard let q = quote else { return "\(code) --" }
        switch menuBarFormat {
        case .price:
            return String(format: "%.2f", q.price)
        case .codePrice:
            return "\(code) \(String(format: "%.2f", q.price))"
        case .namePrice:
            return "\(resolvedName ?? code) \(String(format: "%.2f", q.price))"
        case .custom:
            let template = menuBarTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !template.isEmpty else { return "\(code) \(String(format: "%.2f", q.price))" }
            return MenuBarTemplate.render(
                template: template,
                code: code,
                name: resolvedName,
                price: q.price,
                change: q.change,
                changePercent: q.changePercent
            )
        }
    }

    var menuBarColor: Color {
        guard let q = quote else { return .secondary }
        return changeColor(q)
    }

    func changeColor(_ q: Quote) -> Color {
        let isUp = q.change > 0
        let isDown = q.change < 0
        switch colorPreset {
        case .international:
            return isUp ? ColorPreset.defaultUp : (isDown ? ColorPreset.defaultDown : ColorPreset.defaultFlat)
        case .chinese:
            return isUp ? ColorPreset.defaultDown : (isDown ? ColorPreset.defaultUp : ColorPreset.defaultFlat)
        case .custom:
            return isUp ? upColor : (isDown ? downColor : flatColor)
        }
    }

    /// 带符号的涨跌幅文本,如 "+1.23 (+0.52%)"
    func changeText(_ q: Quote) -> String {
        let sign = q.change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", q.change))  (\(sign)\(String(format: "%.2f", q.changePercent))%)"
    }
}
