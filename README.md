# StockBar 📈

> 纯菜单栏 Mac 股票行情应用:菜单栏实时显示股价,涨跌一目了然。

[![Build & Release](https://github.com/huandc/StockBar/actions/workflows/release.yml/badge.svg)](https://github.com/huandc/StockBar/actions/workflows/release.yml)

数据来源:默认 [Yahoo Finance](https://finance.yahoo.com/),可在设置中切换**东方财富**,均免费、无需 API Key。

## ✨ 功能

- 菜单栏常驻显示,格式可配:价格 / 代码+价格 / 名称+价格 / 自定义模板
- 多数据源:Yahoo / 东方财富,主源失败自动切换备用源
- 配色:绿涨红跌 / 红涨绿跌 / 自定义涨跌平三色
- 支持美股、A 股、港股,代码历史记录一键切换
- 自动刷新 5 / 10 / 30 / 60 秒可选,仅交易时段自动刷新(休市暂停,手动刷新不受影响)

效果示意:

```
🔍  WiFi  ⚡  100%  ┆  AAPL 305.26  ┆  9:41
```

## 📥 安装

1. 从 [Releases](https://github.com/huandc/StockBar/releases) 下载最新版并解压
2. 把 `StockBar.app` 拖入「应用程序」
3. 首次打开:右键 →「打开」→ 确认(应用未公证)

## 🚀 使用

点击菜单栏数字弹出面板,右上角 ⚙️ 进入设置,改完点「保存」。

| 设置项 | 说明 |
| --- | --- |
| 股票代码 | 输入代码,或点输入框旁「时钟」选历史记录 |
| 数据源 | Yahoo / 东方财富 |
| 菜单栏格式 | 价格 / 代码+价格 / 名称+价格 / 自定义模板 |
| 自定义名称 | 别名优先;格式不含名称即隐藏 |
| 配色方案 | 国际 / 中国习惯 / 自定义三色 |
| 刷新间隔 | 5 / 10 / 30 / 60 秒 |
| 交易时段刷新 | 勾选「仅交易时段自动刷新」,休市时暂停 |

代码写法:A 股沪市 `600519.SS`、深市 `000001.SZ`、港股 `0700.HK`,美股直接写 `AAPL`。

自定义模板占位符:`{name}` `{code}` `{price}` `{change}` `{changePercent}`
示例:`{name} {price}({changePercent}%)` → `贵州茅台 1341.99(-0.98%)`

## 🔧 从源码构建

```bash
git clone git@github.com:huandc/StockBar.git
cd StockBar
swift build -c release
./.build/release/StockBar
```

## ❓ 常见问题

- **菜单栏显示 `--`?** 检查代码格式与网络,点「立即刷新」重试
- **无法访问 Yahoo?** 设置中切到「东方财富」,或开启自动切换备用源
- **如何退出?** 面板 →「退出」(应用无 Dock 图标)
- **支持的系统?** macOS 13 及以上

## 📄 License

[MIT](LICENSE) © 2026
