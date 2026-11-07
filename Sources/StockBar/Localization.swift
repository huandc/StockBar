import Foundation

/// 语言选项(设置页可切换)
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHans = "zh-Hans"
    case en

    var id: String { rawValue }

    /// 语言名称用它自己的语言显示,方便用户在陌生语言界面下找回
    var label: String {
        switch self {
        case .system: return "跟随系统 / Follow System"
        case .zhHans: return "简体中文"
        case .en: return "English"
        }
    }
}

/// 文案查表器:把 `Localizable.strings` 里的中文原文当作 key,按当前语言取值。
/// 之所以用中文原文当 key:界面代码里写的仍是中文,替换 `Text("…")` 为
/// `Text(model.tr("…"))` 时不会引入第二套命名,漏翻时回退到中文原文也不会崩。
struct Localization: Equatable {
    enum Language: String {
        case zhHans = "zh-Hans"
        case en
    }

    let language: Language
    private let bundle: Bundle?

    static let chinese = Localization(language: .zhHans)
    static let english = Localization(language: .en)

    init(language: Language, bundle: Bundle = .module) {
        self.language = language
        if let path = bundle.path(forResource: language.rawValue, ofType: "lproj") {
            self.bundle = Bundle(path: path)
        } else {
            self.bundle = nil
        }
    }

    /// 把用户设置解析成具体语言;「跟随系统」看系统首选语言
    static func resolve(_ setting: AppLanguage, preferred: [String] = Locale.preferredLanguages) -> Localization {
        switch setting {
        case .zhHans: return .chinese
        case .en: return .english
        case .system: return preferred.first?.hasPrefix("zh") == true ? .chinese : .english
        }
    }

    /// 取原文案;找不到时回退到 key 本身(即中文原文)
    func text(_ key: String) -> String {
        guard let bundle else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    /// 取带占位符的文案并填充参数
    func format(_ key: String, _ args: CVarArg...) -> String {
        let template = text(key)
        guard !args.isEmpty else { return template }
        return String(format: template, locale: locale, arguments: args)
    }

    private var locale: Locale {
        Locale(identifier: language == .zhHans ? "zh_Hans" : "en")
    }
}
