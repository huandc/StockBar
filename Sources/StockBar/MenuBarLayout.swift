import AppKit
import Foundation

/// 菜单栏文本宽度处理。
///
/// 状态栏空间有限:名称很长或价格位数变多时,系统会直接裁掉尾部(往往是价格),
/// 提前按最大宽度截断并在前面加省略号,能保证「最关键的数值」始终可见。
enum MenuBarLayout {
    /// 默认最大宽度(点)
    static let defaultMaxWidth: Double = 200
    /// 设置面板可调范围
    static let widthRange: ClosedRange<Double> = 120...400
    /// 0 表示不限制
    static let unlimited: Double = 0

    /// 按最大宽度裁剪文本。超出时从**开头**逐字删除并补省略号,
    /// 这样名称先被牺牲、代码与数值保留在尾部。
    /// - Parameter measure: 文本宽度测量函数,测试可注入以便脱离字体环境
    static func fittingText(
        _ text: String,
        maxWidth: Double,
        measure: (String) -> Double = textWidth
    ) -> String {
        guard maxWidth > 0 else { return text }
        guard measure(text) > maxWidth else { return text }

        let ellipsis = "…"
        var characters = Array(text)
        while !characters.isEmpty {
            characters.removeFirst()
            let candidate = ellipsis + String(characters)
            if measure(candidate) <= maxWidth { return candidate }
        }
        return ellipsis
    }

    /// 用菜单栏字体测量文本宽度(点)
    static func textWidth(_ text: String) -> Double {
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.menuBarFont(ofSize: 0)]
        return Double((text as NSString).size(withAttributes: attributes).width)
    }
}
