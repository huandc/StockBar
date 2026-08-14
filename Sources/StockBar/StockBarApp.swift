import SwiftUI
import AppKit

@main
struct StockBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = QuoteModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

/// 隐藏 Dock 图标,让应用只存在于菜单栏
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

/// 菜单栏上显示的文本(带颜色:涨绿跌红,可切换为中国习惯红涨绿跌)
struct MenuBarLabel: View {
    @ObservedObject var model: QuoteModel

    var body: some View {
        Text(model.menuBarText)
            .foregroundStyle(model.menuBarColor)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .fixedSize()
    }
}
