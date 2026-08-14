import SwiftUI
import AppKit

/// 配色方案:国际(默认,绿涨红跌) / 中国(红涨绿跌) / 自定义
enum ColorPreset: String, CaseIterable, Identifiable {
    case international
    case chinese
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .international: return "国际(绿涨红跌)"
        case .chinese:      return "中国(红涨绿跌)"
        case .custom:       return "自定义"
        }
    }

    /// 默认涨色:绿 #22C55E
    static let defaultUp = Color(red: 0.133, green: 0.773, blue: 0.369)
    /// 默认跌色:红 #EF4444
    static let defaultDown = Color(red: 0.937, green: 0.267, blue: 0.267)
    /// 默认平盘色:灰 #9CA3AF
    static let defaultFlat = Color(red: 0.612, green: 0.639, blue: 0.686)
}

/// RGB 分量,用于把 Color 持久化到 UserDefaults
struct RGBColor: Codable {
    var red: Double
    var green: Double
    var blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }

    func encodeData() -> Data? { try? JSONEncoder().encode(self) }
    static func decode(_ data: Data) -> RGBColor? { try? JSONDecoder().decode(RGBColor.self, from: data) }
}

extension Color {
    /// 转为 sRGB 分量,便于持久化
    var rgb: RGBColor? {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        return RGBColor(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent)
    }
}
