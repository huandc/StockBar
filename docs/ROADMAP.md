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
- [x] **多符号轮显**：菜单栏按固定间隔轮播自选列表(原「菜单栏宽度自适应」里的多符号部分,独立拆出)
  - 新增 `WatchlistRotation`(纯逻辑):解析逗号/中文逗号/分号/换行分隔的输入,统一大写去重、上限 12 个,
    下标循环推进与越界收敛
  - `QuoteModel` 新增 `watchlist`/`rotationEnabled`/`rotationInterval`(默认 10 秒)/`rotationIndex`,
    每轮刷新把自选列表全部拉一次并缓存到 `watchQuotes`;轮显定时器只切缓存、不额外发请求,
    菜单栏文本/配色/名称都跟 `displayedSymbol` 走
  - 设置页新增「菜单栏轮显自选列表」开关 + 自选输入框 + 切换间隔(5/10/30/60 秒),
    实时提示符号数量与当前正在显示的代码
  > 验收:开启后菜单栏按间隔在自选间切换,不额外增加请求;关掉即回到单符号模式。
- [x] **刷新失败的用户提示**：连续失败时菜单栏图标呈现异常态，菜单内显示下次重试时间
  - 新增 `RefreshStatus`(纯函数):菜单栏图标选择(失败→警告三角,降级→循环箭头)与文案生成
  - `QuoteModel` 记录 `consecutiveRefreshFailures` / `lastFailureReason` / `nextRefreshAt`(休市时清空)
  - 菜单栏失败时显示橙色警告图标(带 tooltip);面板显示「连续失败 N 次:请求超时」与「将在 21:30:05 重试」,
    休市时改为「休市暂停自动刷新,开盘后恢复」
  > 验收:断网后菜单栏与面板都能看出「出问题了、什么时候重试」,恢复后图标与文案自动消失。

## P2 — 项目工程化

- [x] Issue / PR 模板、`CONTRIBUTING.md`（英文）
  - `.github/ISSUE_TEMPLATE/` 新增 `bug_report.yml`(浏览器式表单:实际/期望/复现步骤 + macOS 版本、芯片、数据源、
    日志下拉与必填校验)、`feature_request.yml`(问题场景/期望做法/替代方案/涉及范围)、`config.yml`
    (禁用空白 Issue,把使用问题与安全报告引到 README 与私密 advisory)
  - `.github/pull_request_template.md`:概述、关联 Issue、改动类型、验证命令与结果、检查清单、截图
  - `CONTRIBUTING.md`(英文):构建与测试(解释为何只能 `./scripts/test.sh`)、源码职责表、「把可测逻辑抽成纯函数」
    约定、分支与 PR 规则(受保护 + `check` + squash)、Conventional Commits 表、ROADMAP 工作方式、
    新增数据源步骤、`os.Logger` 插值与 `Package.swift` 参数顺序两个环境坑
  - `pr-check.yml` 新增两步:校验所有 Issue 模板/工作流 YAML 可解析、校验模板含 name/description/body 且
    body 项 type 合法;README 增加「参与贡献」段落
  > 验收:开 Issue 时出现结构化表单;开 PR 时自动带出检查清单;模板写坏会被 CI 拦下。
- [x] **README 英文版**：面向英文读者重写一份，并补上近期新增能力
  - 新增 `README.en.md`：功能清单（含多符号轮显、宽度自适应、失败状态可见）、安装、设置表、代码写法、
    模板占位符、从源码构建、排障、贡献与许可
  - 中文 `README.md` 与英文版顶部互加语言切换链接；中文版补齐「轮显 / 最大宽度 / 失败图标」三条功能、
    两行设置项、排障条目，并把 clone 地址从 SSH 改为 HTTPS
  > 验收：两份 README 都能独立看懂安装与配置，语言链接互相可达。
- [ ] **README 截图**：菜单栏 + 面板各一张
  - 卡点：本机 `screencapture -x` 报 `could not create image from display`(无屏幕录制权限/无图形会话)，
    无法自动生成真实截图；需要人工在有屏幕录制权限的桌面会话里补图，再引用到两份 README
  > 验收：`docs/images/` 下有两张实拍图并在 README 中正确显示。
- [x] Homebrew Cask 发布
  - 新增 `Casks/stockbar.rb`:`version` 取自 Release tag、zip 用 `StockBar-#{version}-macOS.zip`,
    `app "StockBar.app"`、`depends_on macos: :ventura`、`livecheck` 走 github_latest、`zap` 清偏好设置,
    `caveats` 说明未公证需右键打开
  - 新增 `scripts/check-cask.sh`(语法 + 下载产物核对 sha256 + 校验包内含可执行文件)与
    `scripts/update-cask.sh <version>`(发布后一键改 version/sha256 并自检)
  - `.github/workflows/cask-check.yml`:改动 `Casks/**` 或两个脚本时自动跑上述核对,防止 cask 指向不存在的产物或旧 sha
  - 中英文 README 增加 Homebrew 安装/升级/卸载说明(Cask 装在主仓库的 `Casks/` 下,`brew tap huandc/stockbar <repo-url>` 即可用,
    不额外维护 tap 仓库)
  > 验收:`ruby -c` 与 `brew style` 通过;`scripts/check-cask.sh` 对 v1.0.0 产物校验一致。
- [x] `swift-format` 配置与 CI 检查
  - 新增 `.swift-format`(基于 6.3 默认配置,改 4 空格缩进、120 列、保留既有换行、不重排 import),
    用 `xcrun swift-format format -i -r` 全量规范化一次(19 个文件,仅空白与折行)
  - 新增 `scripts/format.sh`:默认原地格式化,`--lint` 只检查;`pr-check.yml` 增加「代码格式检查」步骤
    (`lint --strict`),写坏格式的 PR 会被拦住
  - CONTRIBUTING 的风格章节改为「CI 强制」并说明不要在同一个 PR 里重排无关文件
  > 验收:本地跑 `./scripts/format.sh` 后 `git diff` 为空,CI 上 lint 严格模式通过。

## P3 — 国际化(中 / 英)

- [ ] **应用内多语言与语言选项**：界面文案支持简体中文与英文,设置页可切换
  - 语言来源三档：跟随系统 / 简体中文 / English，默认「跟随系统」；选择持久化到 UserDefaults(key `appLanguage`）
  - 资源：`Sources/StockBar/Resources/` 下 `zh-Hans.lproj/Localizable.strings` 与 `en.lproj/Localizable.strings`，
    `Package.swift` 加 `defaultLocalization: "en"` 与 `resources: [.process("Resources")]`，运行时用 `Bundle.module`；
    不用 Xcode String Catalog（SwiftPM 下 `.xcstrings` 支持不稳），保持纯文本 strings 便于 review 与 CI 校验
  - 覆盖范围：面板全部标签/按钮/占位提示、`FetchError.errorDescription` 与 `userFacingReason`、`SourceStatus.summary`
    的「XX 代班 · 原因,3 分钟前自动切换」、`RefreshStatus` 的「下次刷新 / 将在 … 重试 / 休市暂停」、菜单栏模板占位符说明
  - 关键难点：这些文案现在硬编码在没有 Bundle 上下文的纯函数里 → 改成接收 `Localization` 值（内部持有 bundle + locale），
    测试注入固定 bundle，避免测试依赖系统语言
  - 切换即时生效：菜单栏与面板都从 `@Published var appLanguage` 取文案，切换后无需重启；若个别系统 API 缓存，
    在其文档里标注需重启
  - 测试：①两份 strings 的 key 集合必须完全一致（缺失即失败，防止漏翻）②按 `en` / `zh-Hans` 各取若干关键文案断言
    ③`FetchError` 六种原因在两语言下都非空 ④切换语言后 `menuBarText` 与状态行变化
  - 验收：设置里切到 English，面板、错误提示、降级状态、失败重试文案全为英文且无中文残留；切回中文恢复；
    `./scripts/test.sh` 通过；新增 key 一致性检查接入 `pr-check.yml`（或单测）"
## 已完成

- [x] 2026-08-14 初版：菜单栏展示、多数据源（Yahoo / 东方财富）、格式与配色可配置
- [x] 2026-08-21 仅交易时段自动刷新；交易时段可配置
- [x] 2026-10-23 新增 `Tests/StockBarTests`（swift-testing，23 个用例 / 4 个 suite）与 `scripts/test.sh`，CI 增加单元测试步骤
- [x] 2026-10-26 数据源请求加显式超时与指数退避重试，降级日志可区分超时/网络/接口/解析；新增 12 个用例（假传输层，无网络依赖）
- [x] 2026-10-27 数据源降级原因可见：新增 `SourceStatus` 记录切换 from/to/原因/时间与失败计数，设置页展示人话状态行；新增 8 个用例
- [x] 2026-10-28 菜单栏宽度自适应:新增 `MenuBarLayout` 按最大宽度从开头截断(保留代码与价格),设置页加 120–400pt 滑块与不限制开关;新增 8 个用例
- [x] 2026-10-29 刷新失败的用户提示:菜单栏失败显示橙色警告图标,面板显示连续失败原因与下次重试时间,休市提示暂停;新增 7 个用例
- [x] 2026-10-30 多符号轮显:菜单栏按间隔轮播自选列表,每轮统一拉取并缓存,切换只读缓存;新增 8 个用例
- [x] 2026-10-31 工程化入口:Issue 表单(问题反馈/功能建议)+ PR 模板 + 英文 CONTRIBUTING,并把模板校验接进 CI
- [x] 2026-11-02 接入 swift-format:统一 4 空格/120 列并全量格式化,CI 增加 lint --strict 检查与 scripts/format.sh
- [x] 2026-11-03 README 英文版:新增 `README.en.md`(补齐轮显/宽度/失败状态),中英文互加语言切换,中文版同步新能力并改用 HTTPS clone;截图因环境无屏幕录制权限拆为独立条目
- [x] 2026-11-04 Homebrew Cask:新增 Casks/stockbar.rb(含 livecheck/zap/caveats)与 check/update 两个脚本,CI 在改动 cask 时核对版本与 sha256
