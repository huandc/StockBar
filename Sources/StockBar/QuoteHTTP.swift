import Foundation
import os

/// 统一日志:数据源请求与降级都走这里,
/// 便于用 Console.app / `log stream --predicate 'subsystem == "StockBar"'` 区分
/// 「超时」「网络错误」「接口错误」「解析失败」。
enum QuoteLog {
    private static let subsystem = "StockBar"

    /// 单次请求:重试、状态码、失败原因
    static let fetch = Logger(subsystem: subsystem, category: "fetch")
    /// 数据源降级(主源 → 备用源)
    static let fallback = Logger(subsystem: subsystem, category: "fallback")
}

/// 一次 HTTP 响应的最小抽象:把 URLSession 挡在协议后面,测试可注入假传输层
protocol HTTPTransporting: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// 默认传输层:显式配置超时与连接策略,避免系统默认的长等待
struct URLSessionTransport: HTTPTransporting {
    static let requestTimeout: TimeInterval = 6
    static let resourceTimeout: TimeInterval = 12

    /// 复用单个会话,避免每次行情刷新都新建 URLSession
    static let sharedSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()

    private let session: URLSession

    init(session: URLSession = URLSessionTransport.sharedSession) {
        self.session = session
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FetchError.network("响应不是 HTTP")
        }
        return (data, http)
    }
}

/// 重试策略:只重试可恢复的失败(超时、连接类错误、5xx、429),
/// 指数退避并设上限;接口错误与解析失败不重试,交给上层降级。
struct RetryPolicy: Equatable, Sendable {
    var maxAttempts: Int
    var baseDelay: TimeInterval
    var maxDelay: TimeInterval

    init(maxAttempts: Int = 3, baseDelay: TimeInterval = 0.4, maxDelay: TimeInterval = 5) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    /// 第 attempt 次失败后等待多久再试(attempt 从 1 起,指数增长并封顶)
    func delay(afterAttempt attempt: Int) -> TimeInterval {
        guard attempt >= 1 else { return 0 }
        return min(baseDelay * pow(2, Double(attempt - 1)), maxDelay)
    }

    func shouldRetry(_ error: FetchError, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }
        switch error {
        case .timeout, .network:
            return true
        case .http(let code):
            return code == 429 || (500..<600).contains(code)
        case .api, .noData:
            return false
        }
    }
}

/// 带重试的行情请求执行器
struct QuoteHTTPClient: Sendable {
    private let transport: any HTTPTransporting
    private let policy: RetryPolicy
    private let sleep: @Sendable (TimeInterval) async throws -> Void

    init(
        transport: any HTTPTransporting = URLSessionTransport(),
        policy: RetryPolicy = RetryPolicy(),
        sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { seconds in
            guard seconds > 0 else { return }
            try await Task.sleep(for: .seconds(seconds))
        }
    ) {
        self.transport = transport
        self.policy = policy
        self.sleep = sleep
    }

    /// 发起请求并按策略重试;`label` 只用于日志定位(如 "yahoo AAPL")
    func data(for request: URLRequest, label: String, policy override: RetryPolicy? = nil) async throws -> Data {
        let policy = override ?? self.policy
        var attempt = 1
        while true {
            do {
                let (data, http) = try await transport.send(request)
                guard (200..<300).contains(http.statusCode) else {
                    throw FetchError.http(http.statusCode)
                }
                if attempt > 1 {
                    QuoteLog.fetch.notice("\(label, privacy: .public) 第 \(attempt) 次尝试成功")
                }
                return data
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let fetchError = FetchError.map(error)
                guard policy.shouldRetry(fetchError, attempt: attempt) else {
                    QuoteLog.fetch.error("\(label, privacy: .public) 请求失败 attempt=\(attempt) reason=\(fetchError.logReason, privacy: .public)")
                    throw fetchError
                }
                let delay = policy.delay(afterAttempt: attempt)
                QuoteLog.fetch.notice("\(label, privacy: .public) 请求失败 attempt=\(attempt) reason=\(fetchError.logReason, privacy: .public),\(delay, format: .fixed(precision: 2))s 后重试")
                try await sleep(delay)
                attempt += 1
            }
        }
    }
}
