import Foundation
import Testing

@testable import StockBar

struct MenuBarClickActionTests {
    @Test("三种点击行为都有中英文案,且提示与行为对应")
    func labelsAreLocalized() {
        #expect(MenuBarClickAction.allCases.count == 3)
        #expect(MenuBarClickAction.openPanel.label(.chinese) == "弹出面板")
        #expect(MenuBarClickAction.openPanel.label(.english) == "Open panel")
        #expect(MenuBarClickAction.refresh.label(.chinese) == "立即刷新")
        #expect(MenuBarClickAction.nextSymbol.label(.english) == "Next symbol")

        // 「立即刷新」模式下必须告诉用户面板改由右键打开,否则会以为面板丢了
        #expect(MenuBarClickAction.refresh.hint(.chinese).contains("右键"))
        #expect(MenuBarClickAction.refresh.hint(.english).lowercased().contains("right-click"))
        #expect(MenuBarClickAction.nextSymbol.hint(.english).lowercased().contains("rotation"))
    }

    @Test("rawValue 稳定,便于写进 JSON 与 UserDefaults")
    func rawValuesAreStable() {
        #expect(MenuBarClickAction.openPanel.rawValue == "openPanel")
        #expect(MenuBarClickAction.refresh.rawValue == "refresh")
        #expect(MenuBarClickAction.nextSymbol.rawValue == "nextSymbol")
        #expect(MenuBarClickAction(rawValue: "refresh") == .refresh)
        #expect(MenuBarClickAction(rawValue: "") == nil)
    }
}
