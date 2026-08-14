import Foundation

/// 股票代码格式映射:统一使用 Yahoo 风格输入(AAPL / 600519.SS / 000001.SZ / 0700.HK / 832000.BJ),
/// 转换为各数据源所需格式。东方财富 secid = "{市场号}.{代码}",市场号经接口实测:
/// 0=深市, 1=沪市, 105=美股, 116=港股(北交所按深市 0 处理,待实测)。
enum SymbolMapper {

    /// 解析 Yahoo 风格代码 → 东方财富 (市场号, 代码)
    static func eastMoneyMarketAndCode(_ raw: String) -> (market: Int, code: String)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()
        guard !upper.isEmpty else { return nil }

        if let dot = upper.firstIndex(of: ".") {
            let code = String(upper[..<dot])
            let suffix = String(upper[upper.index(after: dot)...])
            switch suffix {
            case "SS": return (1, code)                     // 沪市
            case "SZ": return (0, code)                     // 深市
            case "BJ": return (0, code)                     // 北交所(待实测)
            case "HK":
                guard !code.isEmpty, code.allSatisfy({ $0.isNumber }), let num = Int(code) else {
                    return nil                              // 港股代码必须为数字
                }
                return (116, String(format: "%05d", num))   // 港股:补零至 5 位
            default: return nil
            }
        }

        // 无后缀:数字开头按 A 股/北交所推断,字母开头按美股
        if let first = upper.first, first.isNumber {
            switch first {
            case "6": return (1, upper)                     // 沪市
            case "0", "3": return (0, upper)                // 深市
            case "4", "8", "9": return (0, upper)           // 北交所(待实测)
            default: return nil
            }
        }
        return (105, upper)                                 // 美股
    }

    /// 构建东方财富 secid,如 1.600519 / 105.AAPL / 116.00700
    static func eastMoneySecid(_ raw: String) -> String? {
        guard let m = eastMoneyMarketAndCode(raw) else { return nil }
        return "\(m.market).\(m.code)"
    }

    /// 价格类字段的默认缩放位(10^scale):A 股=2(÷100), 美股/港股=3(÷1000)
    static func defaultScale(market: Int) -> Int {
        switch market {
        case 105, 116: return 3
        default:       return 2
        }
    }
}
