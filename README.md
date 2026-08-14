# StockBar 📈

> 一个纯菜单栏的 Mac 股票行情应用 —— 在菜单栏实时显示某只股票的当前价格,涨跌颜色一目了然。

[![Build & Release](https://github.com/huandc/StockBar/actions/workflows/release.yml/badge.svg)](https://github.com/huandc/StockBar/actions/workflows/release.yml)

数据来源:[Yahoo Finance](https://finance.yahoo.com/) 免费行情接口,无需 API Key,无需注册。完全免费、开源。

## ✨ 功能特性

- **菜单栏常驻显示**:右上角菜单栏直接展示「代码 + 现价」,一眼可见,不挡屏幕
- **涨跌配色**:默认绿涨红跌,可一键切换为中国习惯的**红涨绿跌**
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

点击菜单栏的 `AAPL 305.26` 弹出面板:

| 功能 | 操作 |
| --- | --- |
| 查看详情 | 名称、现价、涨跌额/幅、行情时间、更新时间 |
| 切换股票 | 输入代码 → 回车或点「保存」,立即生效 |
| 刷新间隔 | 点选 5 / 10 / 30 / 60 秒 |
| 涨跌配色 | 勾选「红涨绿跌(中国习惯)」 |
| 手动刷新 | 点「立即刷新」 |
| 退出应用 | 点「退出」(应用无 Dock 图标,只能从这里退出) |

### 股票代码写法

| 市场 | 格式 | 示例 |
| --- | --- | --- |
| 美股 | 直接代码 | `AAPL`、`MSFT`、`TSLA` |
| A 股·沪市 | 代码 + `.SS` | `600519.SS`(贵州茅台) |
| A 股·深市 | 代码 + `.SZ` | `000001.SZ`(平安银行) |
| 港股 | 代码 + `.HK` | `0700.HK`(腾讯控股) |

## 🔧 从源码构建

**环境要求**:macOS 13+、Swift 5.10+ / Xcode Command Line Tools(无需完整 Xcode)

```bash
git clone git@github.com:huandc/StockBar.git
cd StockBar
swift build -c release
./.build/release/StockBar
```

## 🤝 开发与贡献

项目采用简单的双分支模型:

```
dev(默认分支)──开发都在这里 ──PR──▶ main(受保护,只能通过 PR 合并)
```

- **`dev`**:默认分支,日常开发、所有功能变更都基于它
- **`main`**:受保护分支,不接受直接推送,只能通过 Pull Request 合并;合并后云端自动编译打包并发布到 Releases

### 参与方式

1. Fork 本仓库,`git clone` 你的 fork(默认即 `dev` 分支)
2. 基于 `dev` 创建特性分支:`` git checkout -b feat/xxx ``
3. 修改代码,提交后推送到你的 fork
4. 发起 Pull Request(目标分支选 `dev`),在 PR 中说明改动内容
5. 审核通过后合入 `dev`;累积一定改动后,再由维护者将 `dev` 合并到 `main` 发布新版本

> 非代码类改动(如文档、翻译、Issue 反馈)同样欢迎,直接在 `dev` 上提 PR 即可。

## 📁 项目结构

```
StockBar/
├── Package.swift                    # SwiftPM 工程(executable target, macOS 13+)
├── LICENSE                          # MIT 开源协议
├── .github/workflows/release.yml    # CI:合并到 main 后自动打包发布
└── Sources/StockBar/
    ├── StockBarApp.swift            # @main 入口 + MenuBarExtra 菜单栏
    ├── QuoteModel.swift             # 状态模型:定时刷新、设置持久化、涨跌配色
    ├── StockFetcher.swift           # Yahoo Finance 行情接口客户端
    └── ContentView.swift            # 弹出面板 UI(行情详情 + 设置)
```

## ❓ 常见问题

**菜单栏显示 `--` 或「未获取到行情」?**

- 检查股票代码格式(A 股带 `.SS`/`.SZ`,港股带 `.HK`)
- 检查网络能否访问 Yahoo Finance(国内网络可能需要代理)
- 点「立即刷新」重试

**如何退出应用?**

菜单栏数字 → 面板 → 「退出」。应用无 Dock 图标,Cmd+Tab 里也看不到它。

**为什么首次打开提示无法验证开发者?**

应用未经过 Apple 公证(Notarization)。个人使用不影响,右键 →「打开」即可。

**支持 macOS 版本?**

macOS 13 (Ventura) 及以上(基于 SwiftUI `MenuBarExtra`)。

## 📄 License

[MIT](LICENSE) © 2026 chong.huan
