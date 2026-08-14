import Foundation

/// 一只股票的最新行情
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

/// 从 Yahoo Finance 获取实时行情(无需 API Key)
/// 支持的代码示例: AAPL / MSFT / 600519.SS(茅台) / 000001.SZ / 0700.HK(腾讯)
enum StockFetcher {
    static func fetch(symbol: String) async throws -> Quote {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FetchError.http(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw FetchError.http(http.statusCode)
        }
        return try parse(data: data, symbol: trimmed)
    }

    // MARK: - 解析

    private struct ChartResponse: Decodable {
        let chart: Chart
        struct Chart: Decodable {
            let result: [Result]?
            let error: APIError?
        }
        struct Result: Decodable {
            let meta: Meta
        }
        struct Meta: Decodable {
            let regularMarketPrice: Double
            let previousClose: Double?
            let chartPreviousClose: Double?
            let currency: String?
            let regularMarketTime: TimeInterval?
            let longName: String?
            let shortName: String?
        }
        struct APIError: Decodable {
            let code: String?
            let description: String?
        }
    }

    static func parse(data: Data, symbol: String) throws -> Quote {
        let decoded: ChartResponse
        do {
            decoded = try JSONDecoder().decode(ChartResponse.self, from: data)
        } catch {
            throw FetchError.noData
        }

        if let apiError = decoded.chart.error {
            throw FetchError.api(apiError.description ?? apiError.code ?? "未知错误")
        }
        guard let meta = decoded.chart.result?.first?.meta else {
            throw FetchError.noData
        }

        return Quote(
            symbol: symbol.uppercased(),
            price: meta.regularMarketPrice,
            previousClose: meta.previousClose ?? meta.chartPreviousClose ?? 0,
            currency: meta.currency ?? "",
            marketTime: meta.regularMarketTime.map { Date(timeIntervalSince1970: $0) },
            name: meta.longName ?? meta.shortName
        )
    }
}
