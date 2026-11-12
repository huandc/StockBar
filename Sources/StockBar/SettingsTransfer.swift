import Foundation

/// 设置的可移植快照:换机、多机同步或排障前备份时导出/导入用。
///
/// 约定:字段只增不减,版本号随之递增;解码时缺失字段取默认值、多余字段忽略,
/// 因此旧版本导出的 JSON 仍能导入。所有取值在使用前经过 `sanitized()`,
/// 非法值(未知数据源、越界宽度、坏掉的时段)回落到默认值而不是让导入整体失败。
struct SettingsSnapshot: Codable, Equatable {
    /// 当前导出格式版本,字段有变动时递增
    static let currentVersion = 1

    var settingsVersion: Int = SettingsSnapshot.currentVersion
    var symbol: String = "AAPL"
    var provider: String = QuoteProvider.yahoo.rawValue
    var enableFallback: Bool = true
    var refreshInterval: Int = 10
    var refreshOnlyInSession: Bool = true
    var customSessionsEnabled: Bool = false
    var customSessions: [SessionRange] = []
    var menuBarFormat: String = MenuBarFormat.codePrice.rawValue
    var menuBarTemplate: String = ""
    var menuBarMaxWidth: Double = MenuBarLayout.defaultMaxWidth
    var watchlist: [String] = []
    var rotationEnabled: Bool = false
    var rotationInterval: Int = 10
    var displayName: String = ""
    var colorPreset: String = ColorPreset.international.rawValue
    var upColor: RGBColor?
    var downColor: RGBColor?
    var flatColor: RGBColor?
    var appLanguage: String = AppLanguage.system.rawValue
    var alerts: [PriceAlert] = []

    init(
        settingsVersion: Int = SettingsSnapshot.currentVersion,
        symbol: String = "AAPL",
        provider: String = QuoteProvider.yahoo.rawValue,
        enableFallback: Bool = true,
        refreshInterval: Int = 10,
        refreshOnlyInSession: Bool = true,
        customSessionsEnabled: Bool = false,
        customSessions: [SessionRange] = [],
        menuBarFormat: String = MenuBarFormat.codePrice.rawValue,
        menuBarTemplate: String = "",
        menuBarMaxWidth: Double = MenuBarLayout.defaultMaxWidth,
        watchlist: [String] = [],
        rotationEnabled: Bool = false,
        rotationInterval: Int = 10,
        displayName: String = "",
        colorPreset: String = ColorPreset.international.rawValue,
        upColor: RGBColor? = nil,
        downColor: RGBColor? = nil,
        flatColor: RGBColor? = nil,
        appLanguage: String = AppLanguage.system.rawValue,
        alerts: [PriceAlert] = []
    ) {
        self.settingsVersion = settingsVersion
        self.symbol = symbol
        self.provider = provider
        self.enableFallback = enableFallback
        self.refreshInterval = refreshInterval
        self.refreshOnlyInSession = refreshOnlyInSession
        self.customSessionsEnabled = customSessionsEnabled
        self.customSessions = customSessions
        self.menuBarFormat = menuBarFormat
        self.menuBarTemplate = menuBarTemplate
        self.menuBarMaxWidth = menuBarMaxWidth
        self.watchlist = watchlist
        self.rotationEnabled = rotationEnabled
        self.rotationInterval = rotationInterval
        self.displayName = displayName
        self.colorPreset = colorPreset
        self.upColor = upColor
        self.downColor = downColor
        self.flatColor = flatColor
        self.appLanguage = appLanguage
        self.alerts = alerts
    }

    /// 手写解码:缺字段用默认值,避免旧导出或手工编辑过的 JSON 直接失败
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SettingsSnapshot()
        settingsVersion =
            try container.decodeIfPresent(Int.self, forKey: .settingsVersion)
            ?? SettingsSnapshot.currentVersion
        symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? defaults.symbol
        provider = try container.decodeIfPresent(String.self, forKey: .provider) ?? defaults.provider
        enableFallback =
            try container.decodeIfPresent(Bool.self, forKey: .enableFallback) ?? defaults.enableFallback
        refreshInterval =
            try container.decodeIfPresent(Int.self, forKey: .refreshInterval) ?? defaults.refreshInterval
        refreshOnlyInSession =
            try container.decodeIfPresent(Bool.self, forKey: .refreshOnlyInSession)
            ?? defaults.refreshOnlyInSession
        customSessionsEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .customSessionsEnabled)
            ?? defaults.customSessionsEnabled
        customSessions =
            try container.decodeIfPresent([SessionRange].self, forKey: .customSessions)
            ?? defaults.customSessions
        menuBarFormat =
            try container.decodeIfPresent(String.self, forKey: .menuBarFormat) ?? defaults.menuBarFormat
        menuBarTemplate =
            try container.decodeIfPresent(String.self, forKey: .menuBarTemplate) ?? defaults.menuBarTemplate
        menuBarMaxWidth =
            try container.decodeIfPresent(Double.self, forKey: .menuBarMaxWidth) ?? defaults.menuBarMaxWidth
        watchlist = try container.decodeIfPresent([String].self, forKey: .watchlist) ?? defaults.watchlist
        rotationEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .rotationEnabled) ?? defaults.rotationEnabled
        rotationInterval =
            try container.decodeIfPresent(Int.self, forKey: .rotationInterval) ?? defaults.rotationInterval
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? defaults.displayName
        colorPreset =
            try container.decodeIfPresent(String.self, forKey: .colorPreset) ?? defaults.colorPreset
        upColor = try container.decodeIfPresent(RGBColor.self, forKey: .upColor)
        downColor = try container.decodeIfPresent(RGBColor.self, forKey: .downColor)
        flatColor = try container.decodeIfPresent(RGBColor.self, forKey: .flatColor)
        appLanguage =
            try container.decodeIfPresent(String.self, forKey: .appLanguage) ?? defaults.appLanguage
        alerts = try container.decodeIfPresent([PriceAlert].self, forKey: .alerts) ?? defaults.alerts
    }

    /// 把越界/未知/重复的取值收敛到可用值,保证导入后不会出现半截状态
    func sanitized() -> SettingsSnapshot {
        var copy = self
        copy.settingsVersion = SettingsSnapshot.currentVersion
        copy.symbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if copy.symbol.isEmpty { copy.symbol = "AAPL" }

        if QuoteProvider(rawValue: provider) == nil { copy.provider = QuoteProvider.yahoo.rawValue }
        if MenuBarFormat(rawValue: menuBarFormat) == nil {
            copy.menuBarFormat = MenuBarFormat.codePrice.rawValue
        }
        if ColorPreset(rawValue: colorPreset) == nil {
            copy.colorPreset = ColorPreset.international.rawValue
        }
        if AppLanguage(rawValue: appLanguage) == nil { copy.appLanguage = AppLanguage.system.rawValue }

        copy.refreshInterval = Self.snapInterval(refreshInterval)
        copy.rotationInterval = Self.snapInterval(rotationInterval)
        copy.menuBarMaxWidth = Self.snapWidth(menuBarMaxWidth)
        copy.menuBarTemplate = menuBarTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.watchlist = WatchlistRotation.normalize(WatchlistRotation.join(watchlist))

        copy.customSessions = customSessions.filter {
            $0.startMinute >= 0 && $0.endMinute <= 24 * 60 && $0.startMinute < $0.endMinute
        }
        if copy.customSessions.isEmpty { copy.customSessionsEnabled = false }

        copy.alerts = dedupe(alerts)
        copy.upColor = upColor.map(Self.clampComponents)
        copy.downColor = downColor.map(Self.clampComponents)
        copy.flatColor = flatColor.map(Self.clampComponents)
        return copy
    }

    /// 刷新间隔只接受界面提供的几档,其余按最近档位吸附
    private static let intervalChoices = [5, 10, 30, 60]

    static func snapInterval(_ value: Int) -> Int {
        intervalChoices.min { abs($0 - value) < abs($1 - value) } ?? 10
    }

    /// 宽度只允许 0(不限制)或 120…400
    static func snapWidth(_ value: Double) -> Double {
        if value <= 0 { return MenuBarLayout.unlimited }
        return min(max(value.rounded(), MenuBarLayout.widthRange.lowerBound), MenuBarLayout.widthRange.upperBound)
    }

    private static func clampComponents(_ color: RGBColor) -> RGBColor {
        func clamp(_ v: Double) -> Double { min(max(v, 0), 1) }
        return RGBColor(red: clamp(color.red), green: clamp(color.green), blue: clamp(color.blue))
    }

    /// 同一代码 + 方向 + 阈值只保留一条,阈值非法或代码为空的丢弃
    private func dedupe(_ alerts: [PriceAlert]) -> [PriceAlert] {
        var seen = Set<String>()
        var result: [PriceAlert] = []
        for alert in alerts {
            let symbol = alert.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !symbol.isEmpty, alert.threshold > 0, alert.threshold.isFinite else { continue }
            let key = "\(symbol)|\(alert.direction.rawValue)|\(alert.threshold)"
            guard seen.insert(key).inserted else { continue }
            var normalized = alert
            normalized.symbol = symbol
            result.append(normalized)
            if result.count == WatchlistRotation.maxSymbols * 2 { break }
        }
        return result
    }
}

/// 设置导入导出失败的原因,直接用于界面提示
enum SettingsTransferError: LocalizedError, Equatable {
    case empty
    case invalidJSON(String)
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .empty: return "没有可导入的内容"
        case .invalidJSON(let detail): return "JSON 解析失败:\(detail)"
        case .unsupportedVersion(let version): return "导入的格式版本 \(version) 比当前版本新,请先升级应用"
        }
    }
}

/// 设置 JSON 的编解码入口(纯函数,便于测试)
enum SettingsTransfer {
    /// 序列化为带缩进的 JSON,便于用户手改后再导入
    static func encode(_ snapshot: SettingsSnapshot) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(snapshot),
            let text = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return text
    }

    /// 解析并收敛;JSON 非法或版本超前时抛错
    static func decode(_ text: String) throws -> SettingsSnapshot {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SettingsTransferError.empty }
        guard let data = trimmed.data(using: .utf8) else {
            throw SettingsTransferError.invalidJSON("不是 UTF-8 文本")
        }
        let decoded: SettingsSnapshot
        do {
            decoded = try JSONDecoder().decode(SettingsSnapshot.self, from: data)
        } catch {
            throw SettingsTransferError.invalidJSON(error.localizedDescription)
        }
        if decoded.settingsVersion > SettingsSnapshot.currentVersion {
            throw SettingsTransferError.unsupportedVersion(decoded.settingsVersion)
        }
        return decoded.sanitized()
    }
}
