import Foundation
import Testing

@testable import StockBar

struct SettingsTransferTests {
    /// 固定 UUID,保证同一用例里多次取到的样本相等
    private let alertID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    private var sample: SettingsSnapshot {
        SettingsSnapshot(
            symbol: "600519.SS",
            provider: QuoteProvider.eastmoney.rawValue,
            enableFallback: false,
            refreshInterval: 30,
            refreshOnlyInSession: false,
            customSessionsEnabled: true,
            customSessions: [
                SessionRange(startMinute: 9 * 60 + 30, endMinute: 11 * 60 + 30),
                SessionRange(startMinute: 13 * 60, endMinute: 15 * 60),
            ],
            menuBarFormat: MenuBarFormat.namePrice.rawValue,
            menuBarTemplate: "{name} {price}",
            menuBarMaxWidth: 260,
            watchlist: ["AAPL", "MSFT"],
            rotationEnabled: true,
            rotationInterval: 30,
            displayName: "我的茅台",
            colorPreset: ColorPreset.chinese.rawValue,
            upColor: RGBColor(red: 1, green: 0.2, blue: 0.2),
            downColor: RGBColor(red: 0.2, green: 0.8, blue: 0.2),
            flatColor: RGBColor(red: 0.5, green: 0.5, blue: 0.5),
            appLanguage: AppLanguage.en.rawValue,
            alerts: [PriceAlert(id: alertID, symbol: "600519.SS", threshold: 1400, direction: .above)]
        )
    }

    @Test("JSON 往返后设置不变")
    func roundTrips() throws {
        let text = SettingsTransfer.encode(sample)
        let decoded = try SettingsTransfer.decode(text)

        #expect(decoded == sample)
        #expect(text.contains("\"settingsVersion\" : 1"))
        // 同样的输入必须得到同样的字节,便于用户比对/纳入版本管理
        #expect(SettingsTransfer.encode(sample) == text)
    }

    @Test("缺字段的旧导出使用默认值")
    func fillsMissingFieldsWithDefaults() throws {
        let partial = #"{"symbol":"aapl","refreshInterval":60}"#
        let decoded = try SettingsTransfer.decode(partial)
        let defaults = SettingsSnapshot()

        #expect(decoded.symbol == "AAPL")
        #expect(decoded.refreshInterval == 60)
        #expect(decoded.provider == defaults.provider)
        #expect(decoded.menuBarFormat == defaults.menuBarFormat)
        #expect(decoded.appLanguage == defaults.appLanguage)
        #expect(decoded.alerts.isEmpty)
        #expect(decoded.settingsVersion == SettingsSnapshot.currentVersion)
    }

    @Test("非法取值收敛到可用值而不是整份导入失败")
    func sanitizesOutOfRangeValues() throws {
        let messy = """
            {
              "settingsVersion": 1,
              "symbol": "  ",
              "provider": "nope",
              "refreshInterval": 7,
              "rotationInterval": 45,
              "menuBarFormat": "weird",
              "colorPreset": "weird",
              "appLanguage": "fr",
              "menuBarMaxWidth": 999,
              "watchlist": ["aapl", "AAPL", " msft ", ""],
              "customSessions": [
                {"startMinute": 600, "endMinute": 540},
                {"startMinute": 570, "endMinute": 690}
              ],
              "customSessionsEnabled": true,
              "alerts": [
                {"id": "11111111-1111-1111-1111-111111111111", "symbol": "aapl", "threshold": 100, "direction": "above", "isArmed": true},
                {"id": "22222222-2222-2222-2222-222222222222", "symbol": "AAPL", "threshold": 100, "direction": "above", "isArmed": true},
                {"id": "33333333-3333-3333-3333-333333333333", "symbol": "MSFT", "threshold": -5, "direction": "below", "isArmed": true}
              ]
            }
            """
        let decoded = try SettingsTransfer.decode(messy)

        #expect(decoded.symbol == "AAPL")
        #expect(decoded.provider == QuoteProvider.yahoo.rawValue)
        #expect(decoded.refreshInterval == 5)
        #expect(decoded.rotationInterval == 30)
        #expect(decoded.menuBarFormat == MenuBarFormat.codePrice.rawValue)
        #expect(decoded.colorPreset == ColorPreset.international.rawValue)
        #expect(decoded.appLanguage == AppLanguage.system.rawValue)
        #expect(decoded.menuBarMaxWidth == MenuBarLayout.widthRange.upperBound)
        #expect(decoded.watchlist == ["AAPL", "MSFT"])
        #expect(decoded.customSessions == [SessionRange(startMinute: 570, endMinute: 690)])
        #expect(decoded.alerts.count == 1)
        #expect(decoded.alerts.first?.symbol == "AAPL")
    }

    @Test("空时段列表会顺带关掉「自定义时段」开关")
    func disablesCustomSessionsWhenEmpty() throws {
        let text = #"{"customSessionsEnabled":true,"customSessions":[{"startMinute":700,"endMinute":600}]}"#
        let decoded = try SettingsTransfer.decode(text)

        #expect(decoded.customSessions.isEmpty)
        #expect(decoded.customSessionsEnabled == false)
    }

    @Test("版本超前、JSON 损坏与空输入分别报错")
    func reportsDecodeFailures() {
        #expect(throws: SettingsTransferError.empty) {
            _ = try SettingsTransfer.decode("   \n ")
        }
        #expect(throws: SettingsTransferError.unsupportedVersion(9)) {
            _ = try SettingsTransfer.decode(#"{"settingsVersion":9}"#)
        }
        do {
            _ = try SettingsTransfer.decode("{not json}")
            Issue.record("非法 JSON 应当抛错")
        } catch let error as SettingsTransferError {
            if case .invalidJSON = error { return }
            Issue.record("错误类型不对:\(error)")
        } catch {
            Issue.record("错误类型不对:\(error)")
        }
    }
}
