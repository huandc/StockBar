import AppKit
import Combine
import SwiftUI

/// 承载菜单栏图标与弹出面板。
///
/// 没有用 SwiftUI 的 `MenuBarExtra`:它只允许「点一下弹出面板」这一种行为,
/// 而设置里要求能改成「立即刷新」或「切到下一个符号」,只能自己持有 `NSStatusItem`。
@MainActor
final class StatusItemController: NSObject {
    /// 无图形会话时的自检开关:启动后打印菜单栏项与面板状态再退出
    static let selfTestFlag = "--status-self-test"

    private let model: QuoteModel
    private let statusItem: NSStatusItem
    private var popover: NSPopover?
    private var hostingView: ClickableHostingView<MenuBarLabel>?
    private var cancellable: AnyCancellable?
    private var lengthUpdateScheduled = false

    init(model: QuoteModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        install()
    }

    // MARK: 搭建

    private func install() {
        guard let button = statusItem.button else { return }
        let host = ClickableHostingView(rootView: MenuBarLabel(model: model))
        host.onLeftClick = { [weak self] in self?.handlePrimaryClick() }
        host.onRightClick = { [weak self] in self?.togglePopover() }
        host.translatesAutoresizingMaskIntoConstraints = true
        host.autoresizingMask = [.width, .height]
        button.addSubview(host)
        hostingView = host
        scheduleLengthUpdate()

        // 文本随行情变化(价格、图标、截断宽度),宽度也要跟着变
        cancellable = model.objectWillChange.sink { [weak self] _ in
            self?.scheduleLengthUpdate()
        }
    }

    /// 菜单栏项宽度跟随内容;延迟一拍等 SwiftUI 完成布局
    private func scheduleLengthUpdate() {
        guard !lengthUpdateScheduled else { return }
        lengthUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lengthUpdateScheduled = false
            guard let host = self.hostingView, let button = self.statusItem.button else { return }
            let size = host.fittingSize
            let width = max(size.width, 24)
            if abs(self.statusItem.length - width) > 0.5 {
                self.statusItem.length = width
            }
            host.frame = button.bounds
        }
    }

    /// 自检:确认菜单栏项真的装上了、面板能弹出(CI 或锁屏时也能跑)
    func runSelfTest() {
        let button = statusItem.button
        print("status length=\(statusItem.length) button=\(button != nil) window=\(button?.window != nil)")
        togglePopover()
        let shown = popover?.isShown ?? false
        print("popover shown=\(shown) size=\(popover?.contentSize ?? .zero)")
        if shown { popover?.performClose(nil) }
        print("self-test done")
    }

    // MARK: 点击行为

    private func handlePrimaryClick() {
        switch model.menuBarClickAction {
        case .openPanel:
            togglePopover()
        case .refresh:
            closePopover()
            Task { await model.refresh() }
        case .nextSymbol:
            if model.isRotating {
                model.advanceRotation()
            } else {
                Task { await model.refresh() }
            }
        }
    }

    // MARK: 面板

    private func togglePopover() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }
        let popover = self.popover ?? makePopover()
        self.popover = popover
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        if let popover, popover.isShown { popover.performClose(nil) }
    }

    private func makePopover() -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = false
        let hosting = NSHostingController(rootView: ContentView().environmentObject(model))
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
        return popover
    }
}

/// 能接收左右键点击的 SwiftUI 宿主视图。
///
/// `NSStatusItem` 的按钮被自定义视图盖住后收不到 action,所以由这一层把点击转出去。
final class ClickableHostingView<Content: View>: NSHostingView<Content> {
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            onRightClick?()
        } else {
            onLeftClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}
