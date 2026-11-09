import AppKit
import SwiftUI

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
            .help(model.tr("设置"))
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

            sparkline(for: q)

            if let t = q.marketTime {
                Text(model.trf("行情时间 %@", t.formatted(date: .omitted, time: .standard)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        } else {
            ProgressView()
                .controlSize(.small)
            Text(model.tr("加载中…"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if let summary = model.failureSummary {
            Text(summary)
                .font(.caption)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
        }

        if !model.triggeredAlerts.isEmpty {
            VStack(spacing: 2) {
                ForEach(model.triggeredAlerts) { alert in
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text(alert.line(model.localization))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }

        if let err = model.errorMessage {
            Text(err)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }

        if let plan = model.nextRefreshText {
            Text(plan)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }

        if model.refreshOnlyInSession && !model.marketOpen {
            Text(model.tr("当前休市,暂停自动刷新"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    /// 本次运行期间的价格小走势;采样不足两个点时不显示
    @ViewBuilder
    private func sparkline(for quote: Quote) -> some View {
        let points = model.trend(for: quote.symbol).normalizedPoints()
        if points.count >= 2 {
            GeometryReader { geo in
                Path { path in
                    for (index, point) in points.enumerated() {
                        let position = CGPoint(
                            x: point.x * geo.size.width,
                            y: (1 - point.y) * geo.size.height
                        )
                        if index == 0 {
                            path.move(to: position)
                        } else {
                            path.addLine(to: position)
                        }
                    }
                }
                .stroke(
                    model.changeColor(quote),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 34)
            .padding(.horizontal, 4)
            .accessibilityLabel(model.tr("最近价格走势"))
        }
    }

    // MARK: 底部

    private var footer: some View {
        HStack(spacing: 8) {
            if let t = model.lastUpdated {
                Text(model.trf("更新于 %@", t.formatted(date: .omitted, time: .standard)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(model.tr("尚未更新"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(model.tr("立即刷新")) { model.startRefresh() }
            Button(model.tr("退出"), role: .destructive) { NSApp.terminate(nil) }
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
    @State private var draftRefreshOnlyInSession = true
    @State private var draftCustomSessionsEnabled = false
    /// 自定义时段文本(每行 [开始, 结束],格式 HH:mm)
    @State private var draftSessionTexts: [[String]] = []
    @State private var draftMenuBarFormat: MenuBarFormat = .codePrice
    @State private var draftMenuBarTemplate = ""
    @State private var draftWatchlistText: String = ""
    @State private var draftRotationEnabled: Bool = false
    @State private var draftRotationInterval: Int = 10
    @State private var draftMenuBarMaxWidth = MenuBarLayout.defaultMaxWidth
    @State private var draftDisplayName = ""
    @State private var draftColorPreset: ColorPreset = .international
    @State private var draftUpColor = ColorPreset.defaultUp
    @State private var draftDownColor = ColorPreset.defaultDown
    @State private var draftFlatColor = ColorPreset.defaultFlat
    @State private var draftAppLanguage: AppLanguage = .system
    @State private var draftAlertSymbol = ""
    @State private var draftAlertDirection: AlertDirection = .above
    @State private var draftAlertThreshold = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                Text(model.tr("设置"))
                    .font(.headline)
                Spacer()
            }
            Divider()
            ScrollView {
                settings
            }
            .frame(maxHeight: 520)
            Divider()
            HStack {
                Spacer()
                Button(model.tr("保存")) { save() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .onAppear(perform: loadDrafts)
    }

    // MARK: 设置项(绑定草稿)

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                TextField(model.tr("股票代码,如 AAPL / 600519.SS / 0700.HK"), text: $draftSymbol)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)

                Menu {
                    if model.symbolHistory.isEmpty {
                        Text(model.tr("暂无历史记录"))
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
                .help(model.tr("历史记录"))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.tr("数据源"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(model.tr("数据源"), selection: $draftProvider) {
                        ForEach(QuoteProvider.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                Toggle(model.tr("主源失败自动切换备用源"), isOn: $draftEnableFallback)
                    .font(.caption)
                // 数据源状态:降级时说明「谁代班、为什么切、什么时候切的」
                HStack(spacing: 4) {
                    Image(
                        systemName: model.sourceStatus.isDegraded ? "arrow.triangle.2.circlepath" : "checkmark.circle"
                    )
                    .font(.caption2)
                    .foregroundStyle(model.sourceStatus.isDegraded ? .orange : .secondary)
                    Text(model.sourceStatusText)
                        .font(.caption2)
                        .foregroundStyle(model.sourceStatus.isDegraded ? .secondary : .tertiary)
                        .textSelection(.enabled)
                }
                .help(model.tr("数据源状态：切换原因与时间来自最近一次自动降级"))
            }

            HStack {
                Text(model.tr("刷新间隔"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker(model.tr("刷新间隔"), selection: $draftRefreshInterval) {
                    Text(model.tr("5秒")).tag(5)
                    Text(model.tr("10秒")).tag(10)
                    Text(model.tr("30秒")).tag(30)
                    Text(model.tr("60秒")).tag(60)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Toggle(model.tr("仅交易时段自动刷新"), isOn: $draftRefreshOnlyInSession)
                .font(.caption)

            Toggle(
                model.tr("自定义交易时段"),
                isOn: Binding(
                    get: { draftCustomSessionsEnabled },
                    set: { on in
                        draftCustomSessionsEnabled = on
                        if on && draftSessionTexts.isEmpty {
                            // 首次开启:以当前股票所属市场的默认时段为初始值
                            draftSessionTexts = Market.detect(from: model.symbol).defaultSessionRanges.map {
                                [Self.formatMinute($0.startMinute), Self.formatMinute($0.endMinute)]
                            }
                        }
                    }
                )
            )
            .font(.caption)

            if draftCustomSessionsEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(draftSessionTexts.indices, id: \.self) { i in
                        HStack(spacing: 6) {
                            TextField("09:30", text: $draftSessionTexts[i][0])
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            Text("–")
                                .foregroundStyle(.secondary)
                            TextField("15:00", text: $draftSessionTexts[i][1])
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            Button {
                                draftSessionTexts.remove(at: i)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.caption)
                    }
                    Button {
                        draftSessionTexts.append(["09:30", "15:00"])
                    } label: {
                        Label(model.tr("添加时段"), systemImage: "plus.circle")
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.tr("菜单栏格式"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(model.tr("菜单栏格式"), selection: $draftMenuBarFormat) {
                        ForEach(MenuBarFormat.allCases) { f in
                            Text(f.label(model.localization)).tag(f)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                if draftMenuBarFormat == .custom {
                    TextField(model.tr("模板,如 {name} {price}({changePercent}%)"), text: $draftMenuBarTemplate)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(model.tr("菜单栏最大宽度"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(draftMenuBarMaxWidth <= 0 ? model.tr("不限制") : "\(Int(draftMenuBarMaxWidth)) pt")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Slider(value: $draftMenuBarMaxWidth, in: MenuBarLayout.widthRange, step: 10)
                    .controlSize(.small)
                    .disabled(draftMenuBarMaxWidth <= 0)
                Toggle(
                    model.tr("不限制宽度(名称过长时由系统裁切)"),
                    isOn: Binding(
                        get: { draftMenuBarMaxWidth <= 0 },
                        set: { unlimited in
                            draftMenuBarMaxWidth = unlimited ? MenuBarLayout.unlimited : MenuBarLayout.defaultMaxWidth
                        }
                    )
                )
                .font(.caption2)
                .toggleStyle(.checkbox)
                if draftMenuBarMaxWidth > 0 {
                    Text(model.tr("超出宽度时从开头截断,保留代码与价格;如「…AAPL 190.50」"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle(model.tr("菜单栏轮显自选列表"), isOn: $draftRotationEnabled)
                    .font(.caption)
                if draftRotationEnabled {
                    TextField(model.tr("自选代码,逗号/换行分隔,如 AAPL, 0700.HK, MSFT"), text: $draftWatchlistText)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    HStack {
                        Text(model.tr("切换间隔"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker(model.tr("切换间隔"), selection: $draftRotationInterval) {
                            Text(model.tr("5秒")).tag(5)
                            Text(model.tr("10秒")).tag(10)
                            Text(model.tr("30秒")).tag(30)
                            Text(model.tr("60秒")).tag(60)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .controlSize(.small)
                        Spacer()
                        if model.isRotating {
                            Text(model.trf("正在显示 %@", model.displayedSymbol))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if let hint = rotationHint {
                        Text(hint)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            HStack {
                Text(model.tr("界面语言"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker(model.tr("界面语言"), selection: $draftAppLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
                .help(model.tr("切换界面语言;「跟随系统」按系统首选语言决定"))
            }

            TextField(model.tr("自定义名称(留空 = 接口名称)"), text: $draftDisplayName)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.tr("配色方案"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker(model.tr("配色方案"), selection: $draftColorPreset) {
                        ForEach(ColorPreset.allCases) { p in
                            Text(p.label(model.localization)).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                if draftColorPreset == .custom {
                    HStack(spacing: 12) {
                        ColorPicker(model.tr("涨"), selection: $draftUpColor, supportsOpacity: false)
                        ColorPicker(model.tr("跌"), selection: $draftDownColor, supportsOpacity: false)
                        ColorPicker(model.tr("平"), selection: $draftFlatColor, supportsOpacity: false)
                    }
                    .font(.caption)
                    .controlSize(.small)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(model.tr("价格提醒"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if model.alerts.isEmpty {
                    Text(model.tr("暂无提醒"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(model.alerts) { alert in
                        HStack(spacing: 6) {
                            Text(alert.symbol)
                                .font(.caption.monospaced())
                            Text(alert.direction.label(model.localization))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", alert.threshold))
                                .font(.caption.monospaced())
                            Spacer()
                            if !alert.isArmed {
                                Text(model.tr("已触发"))
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            Button {
                                model.removeAlert(id: alert.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .help(model.tr("删除"))
                        }
                    }
                }
                HStack(spacing: 6) {
                    TextField(model.symbol, text: $draftAlertSymbol)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption.monospaced())
                        .frame(width: 92)
                    Picker("", selection: $draftAlertDirection) {
                        ForEach(AlertDirection.allCases) { direction in
                            Text(direction.label(model.localization)).tag(direction)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                    TextField(model.tr("价格"), text: $draftAlertThreshold)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption.monospaced())
                        .frame(width: 74)
                    Button(model.tr("添加")) {
                        addAlertDraft()
                    }
                    .controlSize(.small)
                }
                Text(model.tr("价格穿越阈值时触发,回到另一侧后自动恢复"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// 把输入框里的代码与价格变成一条提醒
    private func addAlertDraft() {
        guard let threshold = Double(draftAlertThreshold.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        let symbol = draftAlertSymbol.isEmpty ? model.symbol : draftAlertSymbol
        model.addAlert(symbol: symbol, threshold: threshold, direction: draftAlertDirection)
        draftAlertThreshold = ""
    }

    /// 轮显输入校验提示
    private var rotationHint: String? {
        let parsed = WatchlistRotation.normalize(draftWatchlistText)
        if parsed.isEmpty { return model.tr("至少填写两个符号才会轮显;留空则沿用上方单只股票") }
        if parsed.count == 1 { return model.tr("当前只有 1 个符号,不会轮显;再加一个即可") }
        if parsed.count > 1 && parsed.count == WatchlistRotation.maxSymbols {
            return model.trf("最多 %d 个符号,超出的已忽略", WatchlistRotation.maxSymbols)
        }
        return model.trf("共 %d 个符号,每 %d 秒切换一次", parsed.count, draftRotationInterval)
    }

    // MARK: 草稿与保存

    private func loadDrafts() {
        draftSymbol = model.symbol
        draftProvider = model.selectedProvider
        draftEnableFallback = model.enableFallback
        draftRefreshInterval = model.refreshInterval
        draftRefreshOnlyInSession = model.refreshOnlyInSession
        draftCustomSessionsEnabled = model.customSessionsEnabled
        draftSessionTexts = model.customSessions.map {
            [Self.formatMinute($0.startMinute), Self.formatMinute($0.endMinute)]
        }
        draftMenuBarFormat = model.menuBarFormat
        draftMenuBarTemplate = model.menuBarTemplate
        draftMenuBarMaxWidth = model.menuBarMaxWidth
        draftWatchlistText = WatchlistRotation.join(model.watchlist)
        draftRotationEnabled = model.rotationEnabled
        draftRotationInterval = model.rotationInterval
        draftDisplayName = model.displayName
        draftColorPreset = model.colorPreset
        draftUpColor = model.upColor
        draftDownColor = model.downColor
        draftFlatColor = model.flatColor
        draftAppLanguage = model.appLanguage
    }

    private func save() {
        let trimmed = draftSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { model.symbol = trimmed }
        model.selectedProvider = draftProvider
        model.enableFallback = draftEnableFallback
        model.refreshInterval = draftRefreshInterval
        model.refreshOnlyInSession = draftRefreshOnlyInSession
        if draftCustomSessionsEnabled {
            // 校验所有时段格式,全部合法才写入
            var parsed: [SessionRange] = []
            var valid = true
            for row in draftSessionTexts {
                guard row.count == 2,
                    let start = Self.parseMinute(row[0]),
                    let end = Self.parseMinute(row[1])
                else {
                    valid = false
                    break
                }
                parsed.append(SessionRange(startMinute: start, endMinute: end))
            }
            if valid {
                model.customSessions = parsed
            }
        }
        model.customSessionsEnabled = draftCustomSessionsEnabled
        model.menuBarFormat = draftMenuBarFormat
        model.menuBarTemplate = draftMenuBarTemplate
        model.rotationInterval = draftRotationInterval
        model.updateWatchlist(from: draftWatchlistText)
        model.rotationEnabled = draftRotationEnabled
        model.menuBarMaxWidth = draftMenuBarMaxWidth
        model.displayName = draftDisplayName
        model.colorPreset = draftColorPreset
        model.upColor = draftUpColor
        model.downColor = draftDownColor
        model.flatColor = draftFlatColor
        model.appLanguage = draftAppLanguage
        onClose()
    }

    // MARK: 时间文本解析

    /// "HH:mm" → 分钟数(0-1439)
    private static func parseMinute(_ text: String) -> Int? {
        let parts = text.split(separator: ":").map { String($0) }
        guard parts.count == 2,
            let h = Int(parts[0]), let m = Int(parts[1]),
            (0...23).contains(h), (0...59).contains(m)
        else { return nil }
        return h * 60 + m
    }

    /// 分钟数 → "HH:mm"
    private static func formatMinute(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}
