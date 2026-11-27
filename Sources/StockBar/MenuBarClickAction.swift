import Foundation

/// 点击菜单栏图标时的行为(默认弹面板,保持一直以来的人机习惯)
enum MenuBarClickAction: String, CaseIterable, Identifiable {
    /// 弹出/收起面板(默认)
    case openPanel
    /// 立即刷新行情
    case refresh
    /// 切到自选列表的下一个符号(未开启轮显时退化为刷新)
    case nextSymbol

    var id: String { rawValue }

    func label(_ l10n: Localization) -> String {
        switch self {
        case .openPanel: return l10n.text("弹出面板")
        case .refresh: return l10n.text("立即刷新")
        case .nextSymbol: return l10n.text("切到下一个符号")
        }
    }

    /// 设置页里给这条行为配的一句解释
    func hint(_ l10n: Localization) -> String {
        switch self {
        case .openPanel: return l10n.text("点一下展开面板,再点一下收起")
        case .refresh: return l10n.text("点一下立刻拉一次行情,面板需要右键打开")
        case .nextSymbol: return l10n.text("点一下切到自选里的下一只;未开启轮显时等价于立即刷新")
        }
    }
}
