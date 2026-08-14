import Foundation

/// 东方财富行情数据源(无需 API Key,免费接口)
///
/// 接口(2026-08 实测):
/// - 主路径: `push2.eastmoney.com/api/qt/stock/get`(单只,含 f59 缩放位与 f86 时间戳)
/// - 备用路径: `push2.eastmoney.com/api/qt/ulist.np/get`(批量,对深市/北交所更稳定,无时间戳)
///
/// 关键点:东方财富返回整数,价格类字段需除以 10^f59(A 股=2, 美股/港股=3),涨跌幅固定 ÷100;
/// 本实现只用「最新价 + 昨收」自算涨跌额/幅,与 Yahoo 的 Quote 语义保持一致。
struct EastMoneyProvider: QuoteProviding {
    var id: String { "eastmoney" }
    var displayName: String { "东方财富" }

    private static let baseURL = "https://push2.eastmoney.com/api/qt/stock/get"
    private static let ulistURL = "https://push2.eastmoney.com/api/qt/ulist.np/get"

    func fetch(symbol: String) async throws -> Quote {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let secid = SymbolMapper.eastMoneySecid(trimmed),
              let market = SymbolMapper.eastMoneyMarketAndCode(trimmed)?.market else {
            throw FetchError.api("无法解析东方财富代码:\(trimmed)")
        }

        // 主路径失败时降级到 ulist 批量接口
        do {
            return try await fetchSingle(secid: secid, market: market, symbol: trimmed)
        } catch {
            return try await fetchUlist(secid: secid, market: market, symbol: trimmed)
        }
    }

    // MARK: - 主路径:qt/stock/get

    private func fetchSingle(secid: String, market: Int, symbol: String) async throws -> Quote {
        let fields = "f43,f57,f58,f59,f60,f86,f107,f169"
        let url = URL(string: "\(Self.baseURL)?secid=\(secid)&fields=\(fields)")!
        let data = try await getData(from: url)

        let response: StockGetResponse
        do {
            response = try JSONDecoder().decode(StockGetResponse.self, from: data)
        } catch {
            throw FetchError.noData
        }
        guard let d = response.data, let priceValue = d.f43 else {
            throw FetchError.noData
        }

        let scale = Int(d.f59 ?? Double(SymbolMapper.defaultScale(market: market)))
        let divisor = pow(10.0, Double(scale))
        let price = priceValue / divisor
        // 昨收缺失时用「最新价 - 涨跌额」兜底
        let previousClose = (d.f60.map { $0 / divisor })
            ?? (d.f169.map { price - $0 / divisor })
            ?? price

        return Quote(
            symbol: d.f57 ?? symbol.uppercased(),
            price: price,
            previousClose: previousClose,
            currency: "",
            marketTime: d.f86.map { Date(timeIntervalSince1970: $0) },
            name: d.f58
        )
    }

    private struct StockGetResponse: Decodable {
        struct Data: Decodable {
            let f43: Double?   // 最新价(缩放)
            let f57: String?   // 代码
            let f58: String?   // 名称
            let f59: Double?   // 缩放位(10^f59)
            let f60: Double?   // 昨收(缩放)
            let f86: Double?   // 时间戳(Unix 秒)
            let f107: Double?  // 市场号
            let f169: Double?  // 涨跌额(缩放)
        }
        let data: Data?
    }

    // MARK: - 备用路径:ulist.np/get

    private func fetchUlist(secid: String, market: Int, symbol: String) async throws -> Quote {
        let fields = "f2,f4,f12,f13,f14"
        let url = URL(string: "\(Self.ulistURL)?secids=\(secid)&fields=\(fields)")!
        let data = try await getData(from: url)

        let response: UlistResponse
        do {
            response = try JSONDecoder().decode(UlistResponse.self, from: data)
        } catch {
            throw FetchError.noData
        }
        guard let item = response.data?.diff?.first, let priceValue = item.f2 else {
            throw FetchError.noData
        }

        let scale = SymbolMapper.defaultScale(market: Int(item.f13 ?? Double(market)))
        let divisor = pow(10.0, Double(scale))
        let price = priceValue / divisor
        let change = (item.f4 ?? 0) / divisor
        let previousClose = price - change

        return Quote(
            symbol: item.f12 ?? symbol.uppercased(),
            price: price,
            previousClose: previousClose,
            currency: "",
            marketTime: nil, // ulist 接口不返回时间戳
            name: item.f14
        )
    }

    private struct UlistResponse: Decodable {
        struct Data: Decodable {
            let diff: [Item]?
            struct Item: Decodable {
                let f2: Double?   // 最新价(缩放)
                let f4: Double?   // 涨跌额(缩放)
                let f12: String?  // 代码
                let f13: Double?  // 市场号
                let f14: String?  // 名称
            }
        }
        let data: Data?
    }

    // MARK: - 通用请求

    private func getData(from url: URL) async throws -> Data {
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
        return data
    }
}
