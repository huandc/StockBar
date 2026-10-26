import Foundation
import Testing
@testable import StockBar

/// 可编排的假传输层:按脚本依次返回响应或抛错,并记录调用次数
final class ScriptedTransport: HTTPTransporting, @unchecked Sendable {
    enum Step {
        case success(Data, Int)
        case failure(Error)
    }

    private var steps: [Step]
    private(set) var callCount = 0

    init(_ steps: [Step]) {
        self.steps = steps
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        callCount += 1
        guard !steps.isEmpty else { throw FetchError.network("脚本已耗尽") }
        let step = steps.removeFirst()
        switch step {
        case .success(let data, let status):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        case .failure(let error):
            throw error
        }
    }
}

/// 记录重试退避时长,避免测试真的等待
final class SleepRecorder: @unchecked Sendable {
    private(set) var delays: [TimeInterval] = []

    func record(_ seconds: TimeInterval) {
        delays.append(seconds)
    }
}

private func makeClient(
    _ transport: ScriptedTransport,
    policy: RetryPolicy = RetryPolicy(maxAttempts: 3, baseDelay: 0.4, maxDelay: 5),
    recorder: SleepRecorder = SleepRecorder()
) -> QuoteHTTPClient {
    QuoteHTTPClient(transport: transport, policy: policy) { seconds in
        recorder.record(seconds)
    }
}

private func json(_ string: String) -> Data {
    Data(string.utf8)
}

private let successBody = json(#"{"ok":true}"#)

@Suite("QuoteHTTP")
struct QuoteHTTPTests {

    @Test("超时后重试并最终成功")
    func retriesTimeoutThenSucceeds() async throws {
        let transport = ScriptedTransport([
            .failure(URLError(.timedOut)),
            .success(successBody, 200)
        ])
        let recorder = SleepRecorder()
        let client = makeClient(transport, recorder: recorder)

        let data = try await client.data(for: URLRequest(url: URL(string: "https://example.com/a")!), label: "test")

        #expect(data == successBody)
        #expect(transport.callCount == 2)
        #expect(recorder.delays == [0.4])
    }

    @Test("5xx 会重试,4xx 不重试")
    func retriesServerErrorOnly() async throws {
        let serverError = ScriptedTransport([
            .success(json("{}"), 503),
            .success(successBody, 200)
        ])
        let serverClient = makeClient(serverError)
        _ = try await serverClient.data(for: URLRequest(url: URL(string: "https://example.com")!), label: "test")
        #expect(serverError.callCount == 2)

        let notFound = ScriptedTransport([.success(json("{}"), 404)])
        let notFoundClient = makeClient(notFound)
        await #expect(throws: FetchError.http(404)) {
            try await notFoundClient.data(for: URLRequest(url: URL(string: "https://example.com")!), label: "test")
        }
        #expect(notFound.callCount == 1)
    }

    @Test("解析类失败不重试(交给上层降级)")
    func doesNotRetryParseFailures() async throws {
        let transport = ScriptedTransport([.failure(FetchError.noData)])
        let client = makeClient(transport)
        await #expect(throws: FetchError.noData) {
            try await client.data(for: URLRequest(url: URL(string: "https://example.com")!), label: "test")
        }
        #expect(transport.callCount == 1)
    }

    @Test("达到重试上限后抛出原始原因")
    func givesUpAfterMaxAttempts() async throws {
        let transport = ScriptedTransport([
            .failure(URLError(.timedOut)),
            .failure(URLError(.timedOut)),
            .failure(URLError(.timedOut))
        ])
        let recorder = SleepRecorder()
        let client = makeClient(transport, recorder: recorder)

        await #expect(throws: FetchError.timeout) {
            try await client.data(for: URLRequest(url: URL(string: "https://example.com")!), label: "test")
        }
        #expect(transport.callCount == 3)
        #expect(recorder.delays == [0.4, 0.8])
    }

    @Test("可按调用覆盖重试策略(备用路径只请求一次)")
    func perCallPolicyOverride() async throws {
        let transport = ScriptedTransport([.failure(URLError(.timedOut))])
        let client = makeClient(transport)

        await #expect(throws: FetchError.timeout) {
            try await client.data(
                for: URLRequest(url: URL(string: "https://example.com")!),
                label: "test",
                policy: RetryPolicy(maxAttempts: 1)
            )
        }
        #expect(transport.callCount == 1)
    }

    @Test("退避时长指数增长并封顶")
    func backoffGrowsAndCaps() {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.4, maxDelay: 1)
        #expect(policy.delay(afterAttempt: 0) == 0)
        #expect(policy.delay(afterAttempt: 1) == 0.4)
        #expect(policy.delay(afterAttempt: 2) == 0.8)
        #expect(policy.delay(afterAttempt: 3) == 1)
        #expect(policy.delay(afterAttempt: 4) == 1)
    }

    @Test("重试判定:只重试可恢复错误")
    func retryPolicyMatrix() {
        let policy = RetryPolicy(maxAttempts: 3)
        #expect(policy.shouldRetry(.timeout, attempt: 1))
        #expect(policy.shouldRetry(.network("断网"), attempt: 1))
        #expect(policy.shouldRetry(.http(500), attempt: 1))
        #expect(policy.shouldRetry(.http(429), attempt: 1))
        #expect(!policy.shouldRetry(.http(404), attempt: 1))
        #expect(!policy.shouldRetry(.api("invalid"), attempt: 1))
        #expect(!policy.shouldRetry(.noData, attempt: 1))
        // 已到上限不再重试
        #expect(!policy.shouldRetry(.timeout, attempt: 3))
    }

    @Test("URLError 归一化为超时/网络两类")
    func mapsURLErrors() {
        #expect(FetchError.map(URLError(.timedOut)) == .timeout)
        if case .network = FetchError.map(URLError(.notConnectedToInternet)) {} else {
            Issue.record("断网应映射为 .network")
        }
        if case .network = FetchError.map(NSError(domain: "Custom", code: 1)) {} else {
            Issue.record("非 URL 域错误应映射为 .network")
        }
        #expect(FetchError.map(FetchError.api("x")) == .api("x"))
    }

    @Test("日志标记能区分超时与解析失败")
    func logReasonDistinguishesCause() {
        #expect(FetchError.timeout.logReason == "timeout")
        #expect(FetchError.noData.logReason == "parse_or_empty")
        #expect(FetchError.http(503).logReason == "http_503")
        #expect(FetchError.api("bad").logReason == "api_error")
        #expect(FetchError.network("x").logReason == "network")
    }

    @Test("用户可见文案能说明是超时还是解析失败")
    func errorDescriptions() {
        #expect(FetchError.timeout.errorDescription?.contains("超时") == true)
        #expect(FetchError.noData.errorDescription?.contains("未获取到行情") == true)
        #expect(FetchError.http(503).errorDescription?.contains("503") == true)
    }

    @Test("Yahoo 解析:成功响应转成 Quote")
    func yahooParsesQuote() async throws {
        let body = json("""
        {"chart":{"result":[{"meta":{"regularMarketPrice":190.5,"previousClose":189.0,
        "currency":"USD","regularMarketTime":1729000000,"shortName":"Apple Inc."}}]}}
        """)
        let transport = ScriptedTransport([.success(body, 200)])
        let provider = YahooProvider(client: makeClient(transport))

        let quote = try await provider.fetch(symbol: " aapl ")

        #expect(quote.symbol == "AAPL")
        #expect(quote.price == 190.5)
        #expect(quote.previousClose == 189.0)
        #expect(quote.currency == "USD")
        #expect(quote.name == "Apple Inc.")
        #expect(abs(quote.change - 1.5) < 0.0001)
    }

    @Test("东方财富:主路径连续超时后自动降级到 ulist 接口")
    func eastMoneyFallsBackToUlist() async throws {
        let ulist = json(#"{"data":{"diff":[{"f2":12345,"f4":100,"f12":"600519","f13":1,"f14":"贵州茅台"}]}}"#)
        let transport = ScriptedTransport([
            .failure(URLError(.timedOut)),
            .failure(URLError(.timedOut)),
            .success(ulist, 200)
        ])
        let provider = EastMoneyProvider(
            client: makeClient(transport, policy: RetryPolicy(maxAttempts: 2, baseDelay: 0.4))
        )

        let quote = try await provider.fetch(symbol: "600519.SS")

        #expect(transport.callCount == 3)   // 主路径 2 次 + 备用路径 1 次
        #expect(quote.symbol == "600519")
        #expect(abs(quote.price - 123.45) < 0.0001)
        #expect(abs(quote.change - 1.0) < 0.0001)
        #expect(abs(quote.previousClose - 122.45) < 0.0001)
        #expect(quote.name == "贵州茅台")
    }
}
