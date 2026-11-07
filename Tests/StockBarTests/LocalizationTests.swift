import Foundation
import Testing

@testable import StockBar

/// 文案表自身的一致性测试:两份语言文件的 key 必须完全一致,
/// 否则某个语言下会出现回退到中文原文的「漏翻」。
struct LocalizationTests {
    /// 直接从源码树读 strings 文件,便于比对 key 集合(不依赖编译产物)
    private func stringsKeys(of language: String) throws -> Set<String> {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // Tests/StockBarTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // 仓库根
        let file = root.appendingPathComponent("Sources/StockBar/Resources/\(language).lproj/Localizable.strings")
        let content = try String(contentsOf: file, encoding: .utf8)
        var keys: Set<String> = []
        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("\""), let equals = trimmed.range(of: "\" = \"") else { continue }
            let key = String(trimmed[trimmed.index(after: trimmed.startIndex)..<equals.lowerBound])
            keys.insert(key)
        }
        return keys
    }

    @Test("中英文案表的 key 集合完全一致")
    func keySetsMatch() throws {
        let zh = try stringsKeys(of: "zh-Hans")
        let en = try stringsKeys(of: "en")
        #expect(!zh.isEmpty)
        #expect(zh == en, "仅在一侧出现的 key: \(zh.symmetricDifference(en).sorted())")
    }

    @Test("中文界面返回中文原文")
    func chineseText() {
        #expect(Localization.chinese.text("设置") == "设置")
        #expect(Localization.chinese.text("无有效行情数据") == "无有效行情数据")
    }

    @Test("英文界面返回译文,未知 key 回退到原文")
    func englishText() {
        #expect(Localization.english.text("设置") == "Settings")
        #expect(Localization.english.text("请求超时") == "Request timed out")
        // 未登记的 key 原样返回,保证界面不会出现空字符串
        #expect(Localization.english.text("这条文案还没翻译") == "这条文案还没翻译")
    }

    @Test("占位符按语言填充")
    func formattedText() {
        #expect(Localization.chinese.format("%d 分钟前", 3) == "3 分钟前")
        #expect(Localization.english.format("%d 分钟前", 3) == "3 min ago")
        #expect(Localization.english.format("%@ · 正常", "Yahoo Finance") == "Yahoo Finance · Healthy")
        // 参数数量与模板不匹配时不崩溃
        #expect(!Localization.english.format("%@ · 正常").isEmpty)
    }

    @Test("跟随系统:按首选语言解析")
    func resolveSystemLanguage() {
        #expect(Localization.resolve(.system, preferred: ["zh-Hans-CN", "en-US"]) == .chinese)
        #expect(Localization.resolve(.system, preferred: ["en-US"]) == .english)
        #expect(Localization.resolve(.system, preferred: []) == .english)
        // 显式选择时忽略系统偏好
        #expect(Localization.resolve(.en, preferred: ["zh-Hans-CN"]) == .english)
        #expect(Localization.resolve(.zhHans, preferred: ["en-US"]) == .chinese)
    }

    @Test("数据源与错误文案随语言变化")
    func localizedDomainText() {
        #expect(QuoteProvider.eastmoney.displayName(.chinese) == "东方财富")
        #expect(QuoteProvider.eastmoney.displayName(.english) == "EastMoney")
        #expect(FetchError.timeout.userFacingReason(.english) == "Request timed out")
        #expect(FetchError.http(503).userFacingReason(.english) == "Server error 503")
        #expect(FetchError.http(404).message(.english).contains("404"))
    }
}
