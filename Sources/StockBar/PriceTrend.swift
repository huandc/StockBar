import CoreGraphics
import Foundation

/// 一次刷新得到的价格采样点
struct PriceSample: Equatable {
    let at: Date
    let price: Double
}

/// 面板里的小走势(分时采样)。只保留本次运行期间的采样:
/// 不写磁盘,重启后从空白开始 —— 行情接口本身不提供分时数据,
/// 这里展示的是「应用看到的最近几次刷新」。
struct PriceTrend: Equatable {
    /// 最多保留多少个采样点(按 10 秒刷新算,约 20 分钟)
    static let maxSamples = 120

    private(set) var samples: [PriceSample] = []

    var isEmpty: Bool { samples.isEmpty }
    var count: Int { samples.count }

    var lowest: Double? { samples.map(\.price).min() }
    var highest: Double? { samples.map(\.price).max() }

    /// 追加采样;超过容量丢掉最旧的。同一时间点重复写入时覆盖最后一个。
    mutating func append(_ sample: PriceSample) {
        if let last = samples.last, last.at == sample.at {
            samples[samples.count - 1] = sample
        } else {
            samples.append(sample)
        }
        if samples.count > Self.maxSamples {
            samples.removeFirst(samples.count - Self.maxSamples)
        }
    }

    /// 归一化成 [0,1] 坐标:x 从头到尾均匀分布,y 向上为正(0 = 最低价,1 = 最高价)。
    /// 点数少于 2 或价格全相同时返回空数组,由界面决定不画。
    func normalizedPoints() -> [CGPoint] {
        guard samples.count >= 2, let low = lowest, let high = highest else { return [] }
        let span = high - low
        guard span > 0 else { return [] }
        return samples.enumerated().map { index, sample in
            let x = Double(index) / Double(samples.count - 1)
            let y = (sample.price - low) / span
            return CGPoint(x: x, y: y)
        }
    }
}
