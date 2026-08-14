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

## 开机自启(可选)

系统设置 → 通用 → 登录项 → 添加该应用。若使用终端路径,可先用 Automator 或 App 打包工具包一层 `.app`,或直接:

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
