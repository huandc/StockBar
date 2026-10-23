import Foundation
import SwiftUI
import Testing
@testable import StockBar

@Suite("QuoteColors")
struct QuoteColorsTests {

    @Test("RGBColor 经 JSON 编解码后数值不变")
    func jsonRoundTrip() throws {
        let original = RGBColor(red: 0.125, green: 0.5, blue: 0.875)
        let data = try #require(original.encodeData())
        let decoded = try #require(RGBColor.decode(data))
        #expect(decoded.red == original.red)
        #expect(decoded.green == original.green)
        #expect(decoded.blue == original.blue)
    }

    @Test("非法数据解码返回 nil 而非崩溃")
    func decodeGarbage() {
        #expect(RGBColor.decode(Data("not json".utf8)) == nil)
        #expect(RGBColor.decode(Data()) == nil)
    }

    @Test("Color 与 RGBColor 双向往返保持 sRGB 分量")
    func colorRoundTrip() throws {
        let rgb = RGBColor(red: 0.2, green: 0.4, blue: 0.6)
        let back = try #require(rgb.color.rgb)
        #expect(abs(back.red - 0.2) < 0.001)
        #expect(abs(back.green - 0.4) < 0.001)
        #expect(abs(back.blue - 0.6) < 0.001)
    }

    @Test("默认涨跌平颜色与注释中的值一致")
    func defaultPalette() throws {
        let up = try #require(ColorPreset.defaultUp.rgb)
        #expect(abs(up.red - 0.133) < 0.001)
        #expect(abs(up.green - 0.773) < 0.001)
        #expect(abs(up.blue - 0.369) < 0.001)

        let down = try #require(ColorPreset.defaultDown.rgb)
        #expect(abs(down.red - 0.937) < 0.001)
        #expect(abs(down.green - 0.267) < 0.001)
        #expect(abs(down.blue - 0.267) < 0.001)

        let flat = try #require(ColorPreset.defaultFlat.rgb)
        #expect(abs(flat.red - 0.612) < 0.001)
        #expect(abs(flat.green - 0.639) < 0.001)
        #expect(abs(flat.blue - 0.686) < 0.001)
    }

    @Test("配色方案枚举包含三种预设")
    func presetCases() {
        #expect(ColorPreset.allCases.count == 3)
        #expect(ColorPreset.allCases.map(\.rawValue) == ["international", "chinese", "custom"])
        #expect(ColorPreset.allCases.allSatisfy { !$0.label.isEmpty })
    }
}
