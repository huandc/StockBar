# StockBar 📈

> 一个纯菜单栏的 Mac 股票行情应用 —— 在菜单栏实时显示某只股票的当前价格,涨跌颜色一目了然。

[![Build & Release](https://github.com/huandc/StockBar/actions/workflows/release.yml/badge.svg)](https://github.com/huandc/StockBar/actions/workflows/release.yml)

数据来源:默认 [Yahoo Finance](https://finance.yahoo.com/),可在设置中切换为**东方财富**免费行情接口,均无需 API Key、无需注册。完全免费、开源。

## ✨ 功能特性

- **菜单栏常驻显示**:右上角菜单栏直接展示「代码 + 现价」,一眼可见,不挡屏幕
- **多数据源**:默认 Yahoo Finance,可一键切换**东方财富**(国内网络更稳定),开启后主源失败自动切换备用源
- **名称显示自定义**:菜单栏格式可选「价格 / 代码+价格 / 名称+价格 / 自定义模板」,支持自定义别名(如「茅台」)或隐藏名称
- **涨跌配色**:默认绿涨红跌,可切换为中国习惯的**红涨绿跌**,也可自定义涨/跌/平三色
- **实时刷新**:5 / 10 / 30 / 60 秒可选自动刷新,也可手动立即刷新
- **股票详情**:点击菜单栏数字,弹出面板查看名称、现价、涨跌额、涨跌幅、行情时间
- **完全可配置**:支持美股 / A股 / 港股代码,设置自动保存,下次启动沿用
- **纯净体验**:无 Dock 图标、无窗口,只活在菜单栏里

菜单栏效果示意:

```
  🔍  WiFi  ⚡  100%  ┆  AAPL 305.26  ┆  9:41
```

## 📥 安装

1. 打开 [Releases 页面](https://github.com/huandc/StockBar/releases),下载最新版 `StockBar-<版本>-macOS.zip`
2. 解压后把 `StockBar.app` 拖入「应用程序」文件夹
3. 首次打开:因未做苹果公证,需**右键点击 StockBar.app →「打开」→ 再次确认打开**
4. 菜单栏右上角出现 `AAPL --` 即启动成功

> 若提示「无法打开,因为无法验证开发者」:系统设置 → 隐私与安全性 → 仍要打开。

## 🚀 使用方法

点击菜单栏的 `AAPL 305.26` 弹出面板:**右上角 ⚙️ 齿轮进入设置**,所有选项集中管理:

| 功能 | 操作 |
| --- | --- |
| 查看详情 | 名称、现价、涨跌额/幅、行情时间、更新时间 |
| 进入设置 | 点面板右上角 ⚙️ 齿轮 |
| 保存设置 | 设置 → 改完点底部「保存」,统一生效并返回主面板 |
| 切换股票 | 设置 → 输入代码,或点输入框旁「时钟」图标从历史记录选择 → 保存(或直接回车) |
| 切换数据源 | 设置 → 下拉选「Yahoo Finance / 东方财富」,保存后生效 |
| 菜单栏格式 | 设置 → 下拉选「价格 / 代码+价格 / 名称+价格 / 自定义模板」,保存后生效 |
| 自定义名称 | 设置 → 输入别名(如「茅台」)或留空用接口名称;格式不含名称即隐藏 |
| 自定义颜色 | 设置 → 配色方案选「自定义」后分别设置涨/跌/平颜色 |
| 刷新间隔 | 设置 → 下拉选 5 / 10 / 30 / 60 秒,保存后生效 |
| 手动刷新 | 主面板点「立即刷新」 |
| 退出应用 | 主面板点「退出」(应用无 Dock 图标,只能从这里退出) |

> 配色方案默认值:**国际**(默认)涨绿 `#22C55E` / 跌红 `#EF4444` / 平灰 `#9CA3AF`;**中国习惯**红涨绿跌;**自定义**可分别调整三色。

### 菜单栏自定义模板

「菜单栏格式」选「自定义模板」后,用占位符组合任意格式:

| 占位符 | 含义 | 示例值 |
| --- | --- | --- |
| `{name}` | 显示名称(自定义别名优先) | `贵州茅台` |
| `{code}` | 股票代码 | `600519` |
| `{price}` | 现价 | `1341.99` |
| `{change}` | 涨跌额(带符号) | `-13.30` |
| `{changePercent}` | 涨跌幅(带符号) | `-0.98%` |

示例:`{name} {price}({changePercent}%)` → `贵州茅台 1341.99(-0.98%)`

> 名称取值优先级:自定义别名 > 接口返回名称 > 代码;格式中不含名称占位符即隐藏名称。

### 股票代码写法

| 市场 | 格式 | 示例 |
| --- | --- | --- |
| 美股 | 直接代码 | `AAPL`、`MSFT`、`TSLA` |
| A 股·沪市 | 代码 + `.SS` | `600519.SS`(贵州茅台) |
| A 股·深市 | 代码 + `.SZ` | `000001.SZ`(平安银行) |
| 港股 | 代码 + `.HK` | `0700.HK`(腾讯控股) |

> 两种数据源(Yahoo / 东方财富)使用同一套代码写法,切换数据源时无需改动;东方财富内部会自动转换(如 `600519.SS` → secid `1.600519`)。

> 完整功能设计见 [docs/feature-plan.md](docs/feature-plan.md)。

## 🔧 从源码构建

**环境要求**:macOS 13+、Swift 5.10+ / Xcode Command Line Tools(无需完整 Xcode)

```bash
git clone git@github.com:huandc/StockBar.git
cd StockBar
swift build -c release
./.build/release/StockBar
```

## ❓ 常见问题

**菜单栏显示 `--` 或「未获取到行情」?**

- 检查股票代码格式(A 股带 `.SS`/`.SZ`,港股带 `.HK`)
- 检查网络能否访问当前数据源(Yahoo 国内可能需要代理,可切换到「东方财富」)
- 点「立即刷新」重试

**国内无法访问 Yahoo Finance?**

面板 →「数据源」选择「东方财富」立即生效;或勾选「主源失败自动切换备用源」,失败时自动降级,无需手动切换。

**如何退出应用?**

菜单栏数字 → 面板 → 「退出」。应用无 Dock 图标,Cmd+Tab 里也看不到它。

**为什么首次打开提示无法验证开发者?**

应用未经过 Apple 公证(Notarization)。个人使用不影响,右键 →「打开」即可。

**支持 macOS 版本?**

macOS 13 (Ventura) 及以上(基于 SwiftUI `MenuBarExtra`)。

## 🐛 问题反馈

使用中遇到问题,或有功能建议?欢迎提交 Issue:

- 提 Issue 入口:<https://github.com/huandc/StockBar/issues/new>
- 请尽量提供以下信息,方便快速定位:
  - 问题描述与期望行为
  - 复现步骤
  - 股票代码、macOS 版本、应用版本
  - 截图或报错信息

## 📁 项目结构

```
StockBar/
├── Package.swift                    # SwiftPM 工程(executable target, macOS 13+)
├── LICENSE                          # MIT 开源协议
├── cliff.toml                       # git-cliff 配置:Conventional Commits → 变更日志
├── docs/
│   └── feature-plan.md              # 功能设计文档(多数据源、名称显示、配色自定义)
├── .github/workflows/
│   ├── release.yml                  # CI:release/* 分支触发构建、变更日志与发布
│   └── pr-check.yml                 # CI:PR 编译检查 + 标题规范校验
└── Sources/StockBar/
    ├── StockBarApp.swift            # @main 入口 + MenuBarExtra 菜单栏
    ├── QuoteModel.swift             # 状态模型:定时刷新、设置持久化、数据源降级
    ├── QuoteProvider.swift          # 数据源协议 QuoteProviding + 可选数据源枚举
    ├── YahooProvider.swift          # Yahoo Finance 行情实现
    ├── EastMoneyProvider.swift      # 东方财富行情实现(主/备接口 + 数值缩放)
    ├── SymbolMapper.swift           # 股票代码格式映射(Yahoo 风格 ↔ 东方财富 secid)
    ├── DisplayFormat.swift          # 菜单栏显示格式与自定义模板渲染
    ├── QuoteColors.swift            # 配色方案与自定义颜色持久化
    └── ContentView.swift            # 弹出面板 UI(行情详情 + 设置)
```

## 📄 License

[MIT](LICENSE) © 2026 chong.huan
