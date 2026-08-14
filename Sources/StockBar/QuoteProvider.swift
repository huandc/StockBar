import Foundation

/// 一只股票的最新行情(各数据源统一返回该模型)
struct Quote: Codable {
    let symbol: String
    let price: Double
    let previousClose: Double
    let currency: String
    let marketTime: Date?
    let name: String?

    var change: Double { price - previousClose }
    var changePercent: Double { previousClose > 0 ? change / previousClose * 100 : 0 }
}

enum FetchError: LocalizedError {
    case http(Int)
    case api(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .http(let code): return "网络错误(HTTP \(code))"
        case .api(let msg):   return "接口错误:\(msg)"
        case .noData:         return "未获取到行情,请检查股票代码是否有效"
        }
    }
}

/// 行情数据源协议:所有数据源( Yahoo / 东方财富 …)实现该协议,返回统一的 Quote 模型
protocol QuoteProviding {
    var id: String { get }
    var displayName: String { get }
    func fetch(symbol: String) async throws -> Quote
}

/// 可选数据源;`rawValue` 持久化到 UserDefaults(key: "dataSource")
enum QuoteProvider: String, CaseIterable, Identifiable {
    case yahoo
    case eastmoney

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yahoo:     return "Yahoo Finance"
        case .eastmoney: return "东方财富"
        }
    }

    var provider: any QuoteProviding {
        switch self {
        case .yahoo:     return YahooProvider()
        case .eastmoney: return EastMoneyProvider()
        }
    }
}
