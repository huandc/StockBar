# 开发路线图 / 待办清单

本文件是每日迭代任务的工作队列：每次只取一项、做完勾掉、写一行变更摘要。
顺序即优先级，P0 未清空时不新增 P1 之后的条目。

## P0 — 质量地基

- [x] **补单元测试目标**：新增 `Tests/StockBarTests`（swift-testing），覆盖纯逻辑模块：
  - `SymbolMapper.swift`（55 行）：代码转换、交易所后缀、大小写、非法输入
  - `MarketSession.swift`（60 行）：交易时段判定、跨日、周末、边界分钟
  - `DisplayFormat.swift`（40 行）：价格/涨跌幅格式化、小数位、隐藏逻辑
  - `QuoteColors.swift`（46 行）：涨跌配色映射、自定义颜色回退
  > 验收：`swift test` 通过，四个模块每个至少 3 个用例。

- [x] **Provider 请求加超时与重试**：`YahooProvider.swift`、`EastMoneyProvider.swift`、新增 `QuoteHTTP.swift`。
  - 统一 `QuoteHTTPClient`：URLSession 显式 timeout（请求 6s / 资源 12s、`waitsForConnectivity=false`），
    只对超时/连接错误/5xx/429 做指数退避重试（0.4s→0.8s→1.6s，封顶 5s），接口错误与解析失败不重试
  - 东方财富备用接口作为最后一层只请求一次，避免重试叠加；`os.Logger` 区分 timeout / network / http_xxx / api_error / parse_or_empty
  > 验收：断网/慢网情况下不卡死，降级日志能说明是超时还是解析失败。

## P1 — 可用性

- [x] **降级原因可见**：多数据源切换时记录原因，在设置页展示最近一次数据源与降级说明
  - 新增 `SourceStatus`（纯数据结构）承载：生效源、最近一次自动切换的 from/to/原因/时间、连续失败次数
  - `FetchError` 增加 `userFacingReason`（请求超时 / 网络不可用 / 服务端错误 503 / 请求过于频繁 …）
  - 设置页把「当前来源」升级为状态行：降级时显示「东方财富 代班 · Yahoo Finance 请求超时，3 分钟前自动切换」，
    未降级但已失败一次时提示「再失败 1 次切换备用源」
  > 验收：切换/恢复都能在设置页看到人话原因，日志里能查到同样的状态。
- [x] **菜单栏宽度自适应**：长名称、涨跌幅位数变化时不截断
  - 新增 `MenuBarLayout.fittingText`:超宽时从**开头**逐字截断并补省略号,名称先被牺牲、代码与价格留在尾部
  - 设置页新增「菜单栏最大宽度」滑块(120–400pt,默认 200)与「不限制」开关,经 UserDefaults 持久化
  - 裁剪用 `NSFont.menuBarFont` 真实测量,measure 可注入以便单测
  > 验收:长名称股票不再被系统裁掉价格;关掉限制时行为与旧版一致。
- [ ] **多符号轮显**：菜单栏按固定间隔轮播自选列表(原「菜单栏宽度自适应」里的多符号部分,独立拆出)
- [ ] **刷新失败的用户提示**：连续失败时菜单栏图标呈现异常态，菜单内显示下次重试时间

## P2 — 项目工程化

- [ ] Issue / PR 模板、`CONTRIBUTING.md`（英文）
- [ ] README 英文版 + 截图
- [ ] Homebrew Cask 发布
- [ ] `swift-format` 配置与 CI 检查

## 已完成

- [x] 2026-08-14 初版：菜单栏展示、多数据源（Yahoo / 东方财富）、格式与配色可配置
- [x] 2026-08-21 仅交易时段自动刷新；交易时段可配置
- [x] 2026-10-23 新增 `Tests/StockBarTests`（swift-testing，23 个用例 / 4 个 suite）与 `scripts/test.sh`，CI 增加单元测试步骤
- [x] 2026-10-26 数据源请求加显式超时与指数退避重试，降级日志可区分超时/网络/接口/解析；新增 12 个用例（假传输层，无网络依赖）
- [x] 2026-10-27 数据源降级原因可见：新增 `SourceStatus` 记录切换 from/to/原因/时间与失败计数，设置页展示人话状态行；新增 8 个用例
- [x] 2026-10-28 菜单栏宽度自适应:新增 `MenuBarLayout` 按最大宽度从开头截断(保留代码与价格),设置页加 120–400pt 滑块与不限制开关;新增 8 个用例
