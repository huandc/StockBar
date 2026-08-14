import SwiftUI
import AppKit

/// 菜单栏点击后弹出的面板:行情详情 + 设置
struct ContentView: View {
    @EnvironmentObject private var model: QuoteModel
    @State private var draftSymbol = ""

    var body: some View {
        VStack(spacing: 12) {
            header
            Divider()
            settings
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 360)
        .onAppear { draftSymbol = model.symbol }
    }

    // MARK: 行情展示

    @ViewBuilder
    private var header: some View {
        if let q = model.quote {
            VStack(spacing: 4) {
                if let name = model.resolvedName {
                    Text(name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Text(q.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.2f", q.price))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                if !q.currency.isEmpty {
                    Text(q.currency)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(model.changeText(q))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(model.changeColor(q))

            if let t = q.marketTime {
                Text("行情时间 " + t.formatted(date: .omitted, time: .standard))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        } else {
            ProgressView()
                .controlSize(.small)
            Text("加载中…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if let err = model.errorMessage {
            Text(err)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: 设置

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("股票代码,如 AAPL / 600519.SS / 0700.HK", text: $draftSymbol)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(applySymbol)
                Button("保存", action: applySymbol)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("数据源")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("数据源", selection: $model.selectedProvider) {
                        ForEach(QuoteProvider.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Toggle("主源失败自动切换备用源", isOn: $model.enableFallback)
                    .font(.caption)
                Text("当前来源:\(model.activeProvider.displayName)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Text("刷新间隔")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("刷新间隔", selection: $model.refreshInterval) {
                    Text("5秒").tag(5)
                    Text("10秒").tag(10)
                    Text("30秒").tag(30)
                    Text("60秒").tag(60)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("菜单栏格式")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("菜单栏格式", selection: $model.menuBarFormat) {
                        ForEach(MenuBarFormat.allCases) { f in
                            Text(f.label).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                if model.menuBarFormat == .custom {
                    TextField("模板,如 {name} {price}({changePercent}%)", text: $model.menuBarTemplate)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
            }

            TextField("自定义名称(留空 = 接口名称)", text: $model.displayName)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            Toggle("红涨绿跌(中国习惯)", isOn: $model.redUpGreenDown)
                .font(.caption)
        }
    }

    // MARK: 底部

    private var footer: some View {
        HStack(spacing: 8) {
            if let t = model.lastUpdated {
                Text("更新于 " + t.formatted(date: .omitted, time: .standard))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("尚未更新")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("立即刷新") { model.startRefresh() }
            Button("退出", role: .destructive) { NSApp.terminate(nil) }
        }
    }

    private func applySymbol() {
        let trimmed = draftSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model.symbol = trimmed
    }
}
