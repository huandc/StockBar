import AppKit
import Foundation
import Testing

@testable import StockBar

/// 文档图片由 `DocSnapshots` 离屏渲染生成(不是屏幕截图),这里验证它能产出
/// 合法 PNG 且结果可重复 —— 时间相关字段必须冻结,否则每次渲染字节都变。
@MainActor
struct DocSnapshotTests {
    private func renderPair() throws -> (panel: Data, menubar: Data) {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("stockbar-snap-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try DocSnapshots.render(into: root)
        return (
            try Data(contentsOf: root.appendingPathComponent("panel.png")),
            try Data(contentsOf: root.appendingPathComponent("menubar.png"))
        )
    }

    @Test("面板与菜单栏都能渲染成 PNG")
    func rendersPNGs() throws {
        let images = try renderPair()
        for data in [images.panel, images.menubar] {
            #expect(data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]), "不是 PNG")
            #expect(data.count > 2_000, "图片太小,可能渲染成了空白")
        }
    }

    @Test("渲染结果可重复(不依赖当前时间)")
    func deterministic() throws {
        let first = try renderPair()
        let second = try renderPair()
        #expect(first.panel == second.panel)
        #expect(first.menubar == second.menubar)
    }

    @Test("示例行情按当前语言格式化")
    func sampleModelUsesLanguage() {
        let english = DocSnapshots.sampleModel(language: .en)
        #expect(english.menuBarText.contains("600519.SS"))
        #expect(english.sourceStatusText.contains("Healthy"))
        let chinese = DocSnapshots.sampleModel(language: .zhHans)
        #expect(chinese.sourceStatusText.contains("正常"))
    }
}
