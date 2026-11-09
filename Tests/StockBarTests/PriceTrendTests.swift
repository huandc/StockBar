import Foundation
import Testing

@testable import StockBar

struct PriceTrendTests {
    private func sample(_ price: Double, minute: Int) -> PriceSample {
        PriceSample(at: Date(timeIntervalSince1970: Double(minute) * 60), price: price)
    }

    @Test("采样按顺序累积,超出容量丢弃最旧的")
    func trimsOldest() {
        var trend = PriceTrend()
        #expect(trend.isEmpty)
        for index in 0..<(PriceTrend.maxSamples + 5) {
            trend.append(sample(100 + Double(index), minute: index))
        }
        #expect(trend.count == PriceTrend.maxSamples)
        // 最旧的 5 个被丢弃,剩下从第 6 个开始
        #expect(trend.samples.first?.price == 105)
        #expect(trend.samples.last?.price == 100 + Double(PriceTrend.maxSamples + 4))
    }

    @Test("同一时间点的重复采样覆盖而不是追加")
    func overwritesSameTimestamp() {
        var trend = PriceTrend()
        trend.append(sample(100, minute: 0))
        trend.append(sample(101, minute: 1))
        trend.append(sample(102, minute: 1))
        #expect(trend.count == 2)
        #expect(trend.samples.last?.price == 102)
    }

    @Test("归一化:x 从头到尾均匀分布,y 为 0 到 1")
    func normalizedPoints() {
        var trend = PriceTrend()
        trend.append(sample(100, minute: 0))
        trend.append(sample(110, minute: 1))
        trend.append(sample(105, minute: 2))
        let points = trend.normalizedPoints()
        #expect(points.count == 3)
        #expect(points[0] == CGPoint(x: 0, y: 0))
        #expect(points[1] == CGPoint(x: 0.5, y: 1))
        #expect(points[2].x == 1)
        #expect(abs(points[2].y - 0.5) < 0.0001)
    }

    @Test("点数不足或价格全相同时不画")
    func noPointsWhenDegenerate() {
        var trend = PriceTrend()
        #expect(trend.normalizedPoints().isEmpty)

        trend.append(sample(100, minute: 0))
        #expect(trend.normalizedPoints().isEmpty)

        trend.append(sample(100, minute: 1))
        #expect(trend.normalizedPoints().isEmpty)
    }

    @Test("最值与个数")
    func lowestAndHighest() {
        var trend = PriceTrend()
        for (index, price) in [120.0, 99.5, 131.2, 100.0].enumerated() {
            trend.append(sample(price, minute: index))
        }
        #expect(trend.lowest == 99.5)
        #expect(trend.highest == 131.2)
        #expect(trend.count == 4)
    }
}
