# StockBar — 菜单栏股票价格

一个纯菜单栏的 Mac 应用:在菜单栏实时显示某只股票的当前价格,涨绿跌红(可切换中国习惯的红涨绿跌),点击可查看详情与设置。

数据来源:Yahoo Finance 免费行情接口(无需 API Key)。

## 支持的股票代码

| 市场 | 示例 |
| --- | --- |
| 美股 | `AAPL`、`MSFT`、`TSLA` |
| A 股(沪) | `600519.SS`(贵州茅台) |
| A 股(深) | `000001.SZ`(平安银行) |
| 港股 | `0700.HK`(腾讯控股) |

## 编译

```bash
cd stockbar
swift build -c release
```

## 运行

```bash
./.build/release/StockBar
```

启动后菜单栏会出现 `AAPL 234.56` 这样的文本,点击弹出面板:

- 查看名称、价格、涨跌幅、行情时间
- 修改股票代码(输入后回车或点「保存」)
- 调整刷新间隔(5/10/30/60 秒)
- 切换「红涨绿跌(中国习惯)」
- 立即刷新 / 退出

设置会自动保存,下次启动沿用。

## 自动打包 Release(CI)

项目已配置 GitHub Actions:每次推送到 `main` 分支,云端会自动:

1. 在 macOS 上编译 Release 版本
2. 打包成标准的 `StockBar.app`(含 Info.plist、菜单栏应用 `LSUIElement`、ad-hoc 签名)
3. 压缩为 `StockBar-<版本>-macOS.zip` 并发布到 **Releases 页面**

在 https://github.com/huandc/StockBar/releases 下载最新版本。

- 版本号:普通推送自动为 `1.0.<运行序号>`;打 tag `v1.2.0` 则按 `1.2.0` 发布
- 手动触发:仓库 Actions 页面 → **Build & Release** → **Run workflow**
- 下载 zip 解压后,把 `StockBar.app` 拖入「应用程序」即可双击使用(未公证的应用首次需右键 →「打开」确认)

## 开机自启(可选)

下载 Releases 里的 `StockBar.app` 放到「应用程序」后,系统设置 → 通用 → 登录项 → 「+」→ 添加 `StockBar.app` 即可。本地命令行方式:

```bash
ln -sf "$PWD/.build/release/StockBar" ~/Applications/StockBar
```

## 常见问题

- **显示「未获取到行情」**:股票代码无效,或网络无法访问 Yahoo;A 股/港股代码记得带 `.SS` / `.SZ` / `.HK` 后缀。
- **退出**:点菜单栏图标 → 「退出」,应用无 Dock 图标,不能从 Dock 退出。
- **要求 macOS 13+**。

## 项目结构

```
stockbar/
├── Package.swift              # SwiftPM 工程(executable target)
└── Sources/StockBar/
    ├── StockBarApp.swift      # @main 入口 + MenuBarExtra 菜单栏
    ├── QuoteModel.swift       # 状态模型、定时刷新、涨跌配色
    ├── StockFetcher.swift     # Yahoo 行情接口客户端
    └── ContentView.swift      # 弹出面板 UI(详情 + 设置)
```
