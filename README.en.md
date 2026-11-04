# StockBar 📈

> A Mac stock ticker that lives entirely in your menu bar — price and change, one glance.

[English](README.en.md) · [简体中文](README.md)

[![Build & Release](https://github.com/huandc/StockBar/actions/workflows/release.yml/badge.svg)](https://github.com/huandc/StockBar/actions/workflows/release.yml)

Data sources: [Yahoo Finance](https://finance.yahoo.com/) by default, or **EastMoney** from the settings. Both are free and need no API key.

## ✨ Features

- Always-on menu bar display; format is configurable (price / code + price / name + price / custom template)
- Two data sources with automatic failover when the primary one misbehaves
- Colour schemes: green-up / red-down, red-up / green-down, or three custom colours
- US, China A-share and Hong Kong symbols, with a history of recently used codes
- Auto refresh every 5 / 10 / 30 / 60 seconds, optionally only during market hours
- **Watchlist rotation**: cycle several symbols in the menu bar on an interval, from cached quotes (no extra requests)
- **Width-aware menu bar**: long names are truncated from the front so the price always survives
- **Honest failure states**: a warning icon plus "retry at 21:30:05" instead of a silently frozen number

What it looks like:

```
🔍  WiFi  ⚡  100%  ┆  AAPL 305.26  ┆  9:41
```

## 📥 Install

### Homebrew (recommended, upgrades included)

```bash
brew tap huandc/stockbar https://github.com/huandc/StockBar
brew trust --cask huandc/stockbar/stockbar   # Homebrew 7+ asks you to trust third-party taps
brew install --cask stockbar
```

Upgrade with `brew upgrade --cask stockbar`; remove with `brew uninstall --cask stockbar` (add `--zap` to delete preferences too).

### Manual

1. Download the latest build from [Releases](https://github.com/huandc/StockBar/releases) and unzip it
2. Drag `StockBar.app` into `/Applications`
3. First launch: right-click → **Open** → confirm (the app is not notarised)

## 🚀 Usage

Click the number in the menu bar to open the panel; ⚙️ in the top-right opens settings. Hit **Save** when done.

| Setting | What it does |
| --- | --- |
| Symbol | Type a ticker, or pick a recent one from the clock button |
| Data source | Yahoo Finance / EastMoney |
| Menu bar format | Price, code + price, name + price, or a custom template |
| Custom name | Alias takes priority; hidden when the format has no name |
| Colour scheme | International, Chinese convention, or three custom colours |
| Refresh interval | 5 / 10 / 30 / 60 seconds |
| Refresh in market hours only | Pauses auto refresh while the market is closed; manual refresh still works |
| Trading sessions | Custom open/close times per market (defaults per exchange, editable) |
| Menu bar max width | 120–400 pt slider, or unlimited |
| Watchlist rotation | Toggle, symbol list, and rotation interval (5 / 10 / 30 / 60 s) |

Symbol syntax: Shanghai `600519.SS`, Shenzhen `000001.SZ`, Hong Kong `0700.HK`, US tickers as-is (`AAPL`).

Template placeholders: `{name}` `{code}` `{price}` `{change}` `{changePercent}`
Example: `{name} {price}({changePercent}%)` → `Kweichow Moutai 1341.99(-0.98%)`

## 🔧 Build from source

```bash
git clone https://github.com/huandc/StockBar.git
cd StockBar
swift build -c release
./.build/release/StockBar
```

Only Foundation, SwiftUI and AppKit are used — there are no third-party dependencies.

## ❓ Troubleshooting

- **Menu bar shows `--`?** Check the symbol format and your network, then hit **Refresh now**
- **Yahoo unreachable?** Switch to EastMoney, or enable automatic failover
- **Orange warning icon?** The last refresh failed; hover it to see why, and the panel shows when the next retry happens
- **How do I quit?** Panel → **Quit** (the app has no Dock icon)
- **Supported systems?** macOS 13 and newer

## 🤝 Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). `main` is protected: changes go through a PR, must pass the `check` workflow, and are squash-merged with a Conventional Commits title.

## 📄 License

[MIT](LICENSE) © 2026
