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

enum FetchError: LocalizedError, Equatable {
    case http(Int)
    case api(String)
    case noData
    case timeout
    case network(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "网络错误(HTTP \(code))"
        case .api(let msg):   return "接口错误:\(msg)"
        case .noData:         return "未获取到行情,请检查股票代码是否有效"
        case .timeout:        return "请求超时(网络较慢或数据源无响应)"
        case .network(let msg): return "网络错误:\(msg)"
        }
    }

    /// 日志里的短标记:用于快速区分「超时」「网络」「接口」「解析」
    var logReason: String {
        switch self {
        case .http(let code): return "http_\(code)"
        case .api:            return "api_error"
        case .noData:         return "parse_or_empty"
        case .timeout:        return "timeout"
        case .network:        return "network"
        }
    }

    /// 把 URLSession/URLError 归一为 FetchError,便于重试判断与日志归类
    static func map(_ error: Error) -> FetchError {
        if let fetchError = error as? FetchError { return fetchError }
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return .network(nsError.localizedDescription)
        }
        switch URLError.Code(rawValue: nsError.code) {
        case .timedOut:
            return .timeout
        case .cancelled:
            return .network("请求已取消")
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
             .cannotConnectToHost, .dnsLookupFailed, .secureConnectionFailed,
             .internationalRoamingOff, .dataNotAllowed:
            return .network(nsError.localizedDescription)
        default:
            return .network(nsError.localizedDescription)
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
