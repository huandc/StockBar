import SwiftUI
import AppKit

/// 菜单栏点击后弹出的主面板:行情详情 + 右上角齿轮进入设置
struct ContentView: View {
    @EnvironmentObject private var model: QuoteModel
    @State private var showSettings = false

    var body: some View {
        Group {
            if showSettings {
                SettingsView(onClose: { showSettings = false })
            } else {
                mainView
            }
        }
        .padding(16)
        .frame(width: 360)
    }

    // MARK: 主面板(行情展示)

    private var mainView: some View {
        VStack(spacing: 12) {
            header
            Divider()
            footer
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("设置")
        }
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
}

/// 设置面板:右上角齿轮进入;所有选项先改草稿,点「保存」统一生效
struct SettingsView: View {
    @EnvironmentObject private var model: QuoteModel
    var onClose: () -> Void

    // MARK: 草稿状态(保存时才写入模型)

    @State private var draftSymbol = ""
    @State private var draftProvider: QuoteProvider = .yahoo
    @State private var draftEnableFallback = true
    @State private var draftRefreshInterval = 10
    @State private var draftMenuBarFormat: MenuBarFormat = .codePrice
    @State private var draftMenuBarTemplate = ""
    @State private var draftDisplayName = ""
    @State private var draftColorPreset: ColorPreset = .international
    @State private var draftUpColor = ColorPreset.defaultUp
    @State private var draftDownColor = ColorPreset.defaultDown
    @State private var draftFlatColor = ColorPreset.defaultFlat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                Text("设置")
                    .font(.headline)
                Spacer()
            }
            Divider()
            settings
            Divider()
            HStack {
                Spacer()
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .onAppear(perform: loadDrafts)
    }

    // MARK: 设置项(绑定草稿)

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                TextField("股票代码,如 AAPL / 600519.SS / 0700.HK", text: $draftSymbol)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)

                Menu {
                    if model.symbolHistory.isEmpty {
                        Text("暂无历史记录")
                    } else {
                        ForEach(model.symbolHistory, id: \.self) { s in
                            Button(s) { draftSymbol = s }
                        }
                    }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .disabled(model.symbolHistory.isEmpty)
                .help("历史记录")
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("数据源")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("数据源", selection: $draftProvider) {
                        ForEach(QuoteProvider.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                Toggle("主源失败自动切换备用源", isOn: $draftEnableFallback)
                    .font(.caption)
                Text("当前来源:\(model.activeProvider.displayName)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Text("刷新间隔")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("刷新间隔", selection: $draftRefreshInterval) {
                    Text("5秒").tag(5)
                    Text("10秒").tag(10)
                    Text("30秒").tag(30)
                    Text("60秒").tag(60)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("菜单栏格式")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("菜单栏格式", selection: $draftMenuBarFormat) {
                        ForEach(MenuBarFormat.allCases) { f in
                            Text(f.label).tag(f)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                if draftMenuBarFormat == .custom {
                    TextField("模板,如 {name} {price}({changePercent}%)", text: $draftMenuBarTemplate)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
            }

            TextField("自定义名称(留空 = 接口名称)", text: $draftDisplayName)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("配色方案")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("配色方案", selection: $draftColorPreset) {
                        ForEach(ColorPreset.allCases) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                if draftColorPreset == .custom {
                    HStack(spacing: 12) {
                        ColorPicker("涨", selection: $draftUpColor, supportsOpacity: false)
                        ColorPicker("跌", selection: $draftDownColor, supportsOpacity: false)
                        ColorPicker("平", selection: $draftFlatColor, supportsOpacity: false)
                    }
                    .font(.caption)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: 草稿与保存

    private func loadDrafts() {
        draftSymbol = model.symbol
        draftProvider = model.selectedProvider
        draftEnableFallback = model.enableFallback
        draftRefreshInterval = model.refreshInterval
        draftMenuBarFormat = model.menuBarFormat
        draftMenuBarTemplate = model.menuBarTemplate
        draftDisplayName = model.displayName
        draftColorPreset = model.colorPreset
        draftUpColor = model.upColor
        draftDownColor = model.downColor
        draftFlatColor = model.flatColor
    }

    private func save() {
        let trimmed = draftSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { model.symbol = trimmed }
        model.selectedProvider = draftProvider
        model.enableFallback = draftEnableFallback
        model.refreshInterval = draftRefreshInterval
        model.menuBarFormat = draftMenuBarFormat
        model.menuBarTemplate = draftMenuBarTemplate
        model.displayName = draftDisplayName
        model.colorPreset = draftColorPreset
        model.upColor = draftUpColor
        model.downColor = draftDownColor
        model.flatColor = draftFlatColor
        onClose()
    }
}
