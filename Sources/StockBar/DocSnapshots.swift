import AppKit
import SwiftUI

/// 文档截图:用 SwiftUI 的 `ImageRenderer` 把「真实的界面视图」离屏渲染成 PNG。
///
/// 为什么不用 `screencapture`:菜单栏面板要点击状态项才会出现,那需要辅助功能权限
/// (本机报 `-1719`),而且截整条菜单栏会把用户桌面上的其他图标一起拍进公开仓库。
/// 离屏渲染不需要任何权限、结果可重复,CI 里也能跑。
///
/// 用法:`StockBar --render-docs-images docs/images`(或 `./scripts/screenshots.sh`)
@MainActor
enum DocSnapshots {
    static let flag = "--render-docs-images"

    /// 从命令行参数里取出输出目录;没带参数时返回 nil
    static var requestedDirectory: URL? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: flag), args.index(after: index) < args.endIndex else { return nil }
        return URL(fileURLWithPath: args[args.index(after: index)])
    }

    /// 渲染并写出图片;示例行情固定,保证结果可重复
    @discardableResult
    static func render(into directory: URL, language: AppLanguage = .zhHans) throws -> [URL] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let model = sampleModel(language: language)
        var written: [URL] = []
        written.append(try write(panelView(model), name: "panel.png", in: directory))
        written.append(try write(menuBarView(model), name: "menubar.png", in: directory))
        return written
    }

    /// 固定样例:贵州茅台 1341.99(-0.98%),时间为 2026-11-07 15:00
    static func sampleModel(language: AppLanguage) -> QuoteModel {
        let model = QuoteModel()
        model.appLanguage = language
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 7
        components.hour = 15
        components.minute = 0
        let calendar = Calendar(identifier: .gregorian)
        let marketTime = calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
        // 冻结「下次刷新」时间,保证每次渲染出的图片字节一致
        let nextRefresh = marketTime.addingTimeInterval(10)
        model.seedPreview(
            quote: Quote(
                symbol: "600519.SS",
                price: 1341.99,
                previousClose: 1355.30,
                currency: "CNY",
                marketTime: marketTime,
                name: "贵州茅台"
            ),
            symbol: "600519.SS",
            lastUpdated: marketTime,
            nextRefreshAt: nextRefresh
        )
        return model
    }

    private static func panelView(_ model: QuoteModel) -> some View {
        ContentView()
            .environmentObject(model)
            .background(Color(nsColor: .windowBackgroundColor))
    }

    private static func menuBarView(_ model: QuoteModel) -> some View {
        HStack(spacing: 6) {
            Spacer()
            MenuBarLabel(model: model)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            Spacer()
        }
        .frame(width: 420, height: 30)
        .background(Color(nsColor: NSColor(calibratedWhite: 0.96, alpha: 1)))
    }

    private static func write(_ view: some View, name: String, in directory: URL) throws -> URL {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let cgImage = renderer.cgImage else {
            throw SnapshotError.renderFailed(name)
        }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw SnapshotError.encodeFailed(name)
        }
        let url = directory.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    enum SnapshotError: Error, CustomStringConvertible {
        case renderFailed(String)
        case encodeFailed(String)

        var description: String {
            switch self {
            case .renderFailed(let name): return "渲染失败:\(name)"
            case .encodeFailed(let name): return "PNG 编码失败:\(name)"
            }
        }
    }
}
