import Foundation

/// 菜单栏显示格式
enum MenuBarFormat: String, CaseIterable, Identifiable {
    case price           // 仅价格
    case codePrice       // 代码 + 价格(默认,保持现状)
    case namePrice       // 名称 + 价格
    case custom          // 自定义模板

    var id: String { rawValue }

    var label: String {
        switch self {
        case .price:         return "价格"
        case .codePrice:     return "代码 + 价格"
        case .namePrice:     return "名称 + 价格"
        case .custom:        return "自定义模板"
        }
    }
}

/// 自定义模板渲染,支持占位符:{name} {code} {price} {change} {changePercent}
enum MenuBarTemplate {
    static func render(
        template: String,
        code: String,
        name: String?,
        price: Double,
        change: Double,
        changePercent: Double
    ) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{name}", with: name ?? code)
        result = result.replacingOccurrences(of: "{code}", with: code)
        result = result.replacingOccurrences(of: "{price}", with: String(format: "%.2f", price))
        result = result.replacingOccurrences(of: "{change}", with: String(format: "%+.2f", change))
        result = result.replacingOccurrences(of: "{changePercent}", with: String(format: "%+.2f%%", changePercent))
        return result
    }
}
