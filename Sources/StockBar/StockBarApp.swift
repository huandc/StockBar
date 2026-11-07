import AppKit
import SwiftUI

@main
struct StockBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = QuoteModel()

    init() {
        // 文档截图模式:渲染完即退出,不进入 App 生命周期
        guard let directory = DocSnapshots.requestedDirectory else { return }
        NSApplication.shared.setActivationPolicy(.prohibited)
        do {
            let urls = try DocSnapshots.render(into: directory)
            for url in urls { print("已写出 \(url.path)") }
            exit(0)
        } catch {
            FileHandle.standardError.write(Data("截图渲染失败: \(error)\n".utf8))
            exit(1)
        }
    }

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
        HStack(spacing: 3) {
            // 刷新失败显示警告三角,降级期间显示循环箭头;正常时不占位
            if let symbol = model.menuBarSymbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(model.isFailing ? Color.orange : Color.secondary)
                    .help(model.failureSummary ?? model.tr("当前使用备用数据源"))
            }
            Text(model.menuBarText)
                .foregroundStyle(model.menuBarColor)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .fixedSize()
        }
    }
}
