# StockBar 新增功能设计文档

> 版本:v0.1(评审稿)
> 日期:2026-08-14
> 状态:待评审
> 适用范围:菜单栏股票应用 StockBar(macOS 13+, SwiftUI, SwiftPM)

---

## 1. 需求概述

在现有功能(单数据源 Yahoo Finance、菜单栏「代码 + 价格」、固定涨跌配色)基础上,新增以下能力:

| # | 需求 | 说明 |
| --- | --- | --- |
| 1 | 多数据源 | 默认 **Yahoo Finance**(保持现状),可选配置 **东方财富** 接口,可在设置面板切换 |
| 2 | 名称显示 | 菜单栏/面板的名称支持 **自定义别名** 或 **隐藏**;涨跌颜色支持 **自定义**,并给出明确的**默认值** |

**非目标(本期不做)**:多股票同时显示、走势图、自选股列表、通知提醒。详见 §10 规划。

---

## 2. 现状分析

| 维度 | 现状 | 位置 |
| --- | --- | --- |
| 数据源 | 仅 Yahoo: `query1.finance.yahoo.com/v8/finance/chart/` | `StockFetcher.swift` |
| 菜单栏文案 | 固定「代码 + 价格」,如 `AAPL 305.26` | `QuoteModel.menuBarText` |
| 涨跌配色 | 绿涨红跌;开关「红涨绿跌」整体对调;平盘灰色 | `QuoteModel.changeColor` |
| 名称 | 面板显示接口返回的名称(`longName`),菜单栏不显示 | `ContentView.header` |
| 设置 | `UserDefaults` 持久化:symbol / refreshInterval / redUpGreenDown | `QuoteModel` |

结论:需求 1 需要把「取行情」抽象为可插拔的数据源;需求 2 需要把「菜单栏文案」和「颜色」从硬编码改为可配置。

---

## 3. 功能一:多数据源(默认 Yahoo,可选东方财富)

### 3.1 架构设计

引入数据源协议,现有 Yahoo 逻辑原样收编为其中一个实现:

```swift
/// 行情数据源协议
protocol QuoteProviding {
    var id: String { get }            // "yahoo" / "eastmoney"
    var displayName: String { get }   // "Yahoo Finance" / "东方财富"
    func fetch(symbol: String) async throws -> Quote
}

enum QuoteProvider: String, CaseIterable, Identifiable {
    case yahoo, eastmoney
    var provider: any QuoteProviding { ... }
}
```

- `QuoteModel` 只依赖 `QuoteProviding`,不感知具体数据源;
- 数据源枚举值持久化到 `UserDefaults`(key `dataSource`,默认 `"yahoo"`),下次启动沿用;
- 切换数据源后立即用新源刷新一次。

### 3.2 Yahoo 提供方(现状保留)

沿用现有实现与代码格式(`AAPL` / `600519.SS` / `000001.SZ` / `0700.HK`),仅将 `StockFetcher` 收敛为协议实现,行为不变。

### 3.3 东方财富提供方

#### 3.3.1 接口(已实测验证)

**单只行情(主路径)**

```
GET https://push2.eastmoney.com/api/qt/stock/get
    ?secid={市场号}.{代码}
    &fields=f43,f44,f45,f46,f47,f48,f57,f58,f59,f60,f86,f107,f169,f170
```

**批量行情(备用 / 未来多股路径)**

```
GET https://push2.eastmoney.com/api/qt/ulist.np/get
    ?secids={市场号}.{代码},{市场号}.{代码},...
    &fields=f2,f3,f4,f12,f13,f14
```

请求头与 Yahoo 一致:浏览器 `User-Agent`、`Accept: application/json`、超时 10s。

实测样例(`curl` 于 2026-08-14):

| 股票 | secid | f43 最新价 | f58 名称 | f60 昨收 | f169 涨跌额 | f170 涨跌幅 | f59 缩放 | f86 时间戳 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 贵州茅台 | `1.600519` | 134199 | 贵州茅台 | 135529 | -1330 | -98 | —(按 A 股 2) | 1786694533 |
| 苹果 | `105.AAPL` | 305260 | 苹果 | 302250 | 3010 | 100 | 3 | 1786651200 |
| 腾讯控股 | `116.00700` | 438800 | 腾讯控股 | 441000 | -2200 | -50 | —(按港股 3) | 1786694547 |
| 平安银行 | `0.000001` | 1111(ulist f2) | 平安银行 | — | -14(ulist f4) | -124(ulist f3) | —(按 A 股 2) | — |

> 注:`qt/stock/get` 实测对部分深市/北交所代码偶发空响应,`ulist.np/get` 一次请求覆盖沪深美港全部正常。实现上应「主路径 + 备用路径」双保险(见 3.3.4)。

#### 3.3.2 代码格式映射(用户输入沿用 Yahoo 风格)

用户输入不改变心智负担,统一使用 Yahoo 风格,由映射器按数据源转换:

| 用户输入(Yahoo 风格) | 市场 | 东方财富 secid | 转换规则 |
| --- | --- | --- | --- |
| `AAPL` | 美股 | `105.AAPL` | 无后缀 → 市场号 `105`,代码原样 |
| `600519.SS` | 沪市 | `1.600519` | `.SS` → 市场号 `1` |
| `000001.SZ` | 深市 | `0.000001` | `.SZ` → 市场号 `0` |
| `832000.BJ` | 北交所 | `0.832000` | `.BJ` → 市场号 `0`(待实测) |
| `0700.HK` | 港股 | `116.00700` | `.HK` → 市场号 `116`,去掉点后补零至 5 位 |

市场号已由接口返回字段确认:`f107` / `f13` 返回值 0=深、1=沪、105=美股、116=港股。

**建议**:映射器输出为统一结构 `(market: Int, code: String)`,未来新增数据源(如腾讯行情)可复用。

#### 3.3.3 字段映射与数值缩放(关键坑)

东方财富返回的是**整数**,必须按缩放比例还原,否则价格会差 10 倍以上:

- 价格类字段 `f43`(最新价)、`f60`(昨收)、`f169`(涨跌额)以及 ulist 的 `f2`/`f4`:**除以 `10^f59`**(`f59` 为缩放位,实测美股 = 3;A 股按实测推断 = 2,港股 = 3);
- 涨跌幅 `f170` / ulist `f3`:**固定除以 100**(保留两位小数,如 -98 → -0.98%);
- 时间戳 `f86`:Unix 秒 → `Date`。

**实现建议**:`Quote.change` / `changePercent` 由 `price - previousClose` 自行计算,与 Yahoo 语义完全一致,避免分别处理两套涨跌幅字段的缩放差异。

#### 3.3.4 异常与限流处理

实测观察到接口偶发空响应/限流(连续请求后返回空 body):

1. 主路径 `qt/stock/get` 失败 → 降级 `ulist.np/get`(按市场号默认缩放)重试一次;
2. 仍失败 → 指数退避重试(0.5s / 1s),最多 2 次;
3. 最终失败抛出 `FetchError.api(...)`,面板显示错误信息,与 Yahoo 失败表现一致;
4. 字段缺失兜底:`previousClose` 取 `f60` 或返回「未获取到行情」。

### 3.4 数据源选择与降级

设置面板新增「数据源」分段选择器:**Yahoo Finance(默认)/ 东方财富**。

可选项(建议默认开启):「主源失败自动切换备用源」。开启后,主源连续失败 2 次时用备用源刷新并标记来源;恢复条件为主源连续成功 1 次。

> 场景价值:国内网络访问 Yahoo 不稳,切到东方财富即可;反之东方财富偶发限流时可回 Yahoo。

### 3.5 设置与持久化

| UserDefaults Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `dataSource` | String | `"yahoo"` | 数据源:`yahoo` / `eastmoney` |
| `enableFallback` | Bool | `true` | 主源失败自动切换备用源 |

---

## 4. 功能二:名称显示(自定义 / 隐藏)

### 4.1 现状问题

- 菜单栏只显示「代码 价格」,看不到名称;
- 名称来自数据源:Yahoo 返回英文(`Apple Inc.`),东方财富返回中文(`苹果`),**切换数据源名称会变**。

### 4.2 菜单栏显示格式(可配置)

新增设置「菜单栏格式」,选项与默认值:

| 选项 | 示例 | 说明 |
| --- | --- | --- |
| `codePrice`(默认,保持现状) | `AAPL 305.26` | 代码 + 价格 |
| `namePrice` | `苹果 305.26` | 名称 + 价格 |
| `nameCodePrice` | `苹果 AAPL 305.26` | 名称 + 代码 + 价格 |
| `custom` | `{name} {price}({changePercent}%)` | 自定义模板 |

自定义模板占位符:`{name}` `{code}` `{price}` `{change}` `{changePercent}`,渲染时替换;非法/空模板回退为 `codePrice`。

**名称取值优先级**:用户自定义别名 > 接口返回名称 > 代码(接口无名称时兜底)。

### 4.3 自定义名称与隐藏

- **自定义别名**:设置面板输入框,如把 `600519.SS` 显示为「茅台」;留空则用接口名称;
- **隐藏名称**:选择不含 `{name}` 的格式即可隐藏(独立开关不必要,避免设置冗余);
- 面板头部名称与菜单栏共用同一取值逻辑。

### 4.4 设置与持久化

| UserDefaults Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `menuBarFormat` | String | `"codePrice"` | 菜单栏格式:`codePrice` / `namePrice` / `nameCodePrice` / `custom` |
| `menuBarTemplate` | String | `"{name} {price}"` | 自定义模板(仅 `custom` 生效) |
| `displayName` | String | `""` | 自定义别名,空 = 使用接口名称 |

---

## 5. 功能三:涨跌颜色自定义(含默认值)

### 5.1 现状

- 涨=绿、跌=红(国际习惯),勾选「红涨绿跌」整体对调;平盘固定灰色 `secondary`;
- 颜色硬编码在 `QuoteModel.changeColor`。

### 5.2 配色方案模型与默认值

引入「配色方案」概念,替代单一开关:

| 方案 | 涨 | 跌 | 平 | 说明 |
| --- | --- | --- | --- | --- |
| `international`(默认) | 绿 `#22C55E` | 红 `#EF4444` | 灰 `#9CA3AF` | 即现状「绿涨红跌」 |
| `chinese` | 红 `#EF4444` | 绿 `#22C55E` | 灰 `#9CA3AF` | 即现状「红涨绿跌」 |
| `custom` | 用户自定义 | 用户自定义 | 用户自定义 | 三个 `ColorPicker` |

- 现有「红涨绿跌」开关迁移为「配色方案」选择器(国际 / 中国 / 自定义),旧设置 `redUpGreenDown` 自动映射到对应方案,兼容不丢失;
- 自定义方案下,三个颜色分别用 `ColorPicker` 选择,**默认值沿用对应方案的系统色**(涨绿、跌红、平灰),保证开箱即用。

### 5.3 持久化

`UserDefaults` 不适合直接存 `Color`,采用可编码的 RGB 分量:

| UserDefaults Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `colorPreset` | String | `"international"` | 方案:`international` / `chinese` / `custom` |
| `upColorRGB` | Data(3 × Double) | 绿 `#22C55E` | 自定义涨色 |
| `downColorRGB` | Data(3 × Double) | 红 `#EF4444` | 自定义跌色 |
| `flatColorRGB` | Data(3 × Double) | 灰 `#9CA3AF` | 自定义平盘色 |
| `redUpGreenDown`(旧) | Bool | — | 仅迁移读取,不再写入 |

### 5.4 渲染入口

`QuoteModel.changeColor(_:)` 改为按 `colorPreset` 返回 `Color`,菜单栏与面板共用,改动点收敛在一处。

---

## 6. 设置面板 UI 变更

面板宽度 320 → 360,设置区按分组重排:

```
行情详情(保持不变)
────────────────────────
股票代码: [____________] [保存]
数据源:   [Yahoo Finance | 东方财富]
          ☑ 主源失败自动切换备用源
刷新间隔: [5|10|30|60] 秒
────────────────────────
菜单栏格式: [代码+价格|名称+价格|名称+代码+价格|自定义]
自定义名称: [__________](留空 = 接口名称)
配色方案:  [国际(绿涨红跌)|中国(红涨绿跌)|自定义]
           (自定义时展开三个颜色选择器)
────────────────────────
更新于 09:41     [立即刷新] [退出]
```

---

## 7. 代码结构变更

新增文件:

| 文件 | 职责 |
| --- | --- |
| `Sources/StockBar/QuoteProvider.swift` | `QuoteProviding` 协议 + `QuoteProvider` 枚举 |
| `Sources/StockBar/YahooProvider.swift` | 现有 `StockFetcher` 逻辑收编为协议实现 |
| `Sources/StockBar/EastMoneyProvider.swift` | 东方财富实现:secid 构建、请求、缩放解析、降级重试 |
| `Sources/StockBar/SymbolMapper.swift` | Yahoo 风格代码 ↔ 各源代码格式映射 |
| `Sources/StockBar/DisplayFormat.swift` | 菜单栏格式枚举 + 模板渲染(`{name}` 等占位符) |
| `Sources/StockBar/QuoteColors.swift` | 配色方案枚举、默认色值、RGB 持久化编解码 |

修改文件:

| 文件 | 改动 |
| --- | --- |
| `QuoteModel.swift` | 新增设置项(dataSource / menuBarFormat / displayName / colorPreset …);`menuBarText`、`changeColor` 改为读配置;`refresh()` 走 `QuoteProvider` |
| `ContentView.swift` | 设置区新增数据源、显示格式、自定义名称、配色方案控件 |
| `README.md` | 功能特性、使用说明、项目结构同步更新(发布时一并更新) |

---

## 8. 兼容性与迁移

1. **默认值即现状**:`dataSource=yahoo`、`menuBarFormat=codePrice`、`colorPreset=international`,老用户升级后行为与旧版完全一致;
2. **旧设置迁移**:`redUpGreenDown=true` 首次启动映射为 `colorPreset=chinese`,旧键不再写入;
3. **失败体验一致**:新源失败的错误文案与 Yahoo 风格统一,面板红字提示;
4. **代码格式不变**:用户输入仍为 `AAPL` / `600519.SS` / `000001.SZ` / `0700.HK`,映射对用户透明。

---

## 9. 验收标准

1. **数据源切换**:默认 Yahoo;切到东方财富后,美股 `AAPL`、沪 `600519.SS`、深 `000001.SZ`、港 `0700.HK` 均能正确显示;
2. **缩放正确性**:茅台显示约 `1341.99`(而非 `13419.9`),苹果约 `305.26`,腾讯约 `438.80`;涨跌幅两位小数;
3. **降级**:Yahoo 请求失败(断网/代理不可达)时,开启降级后能通过东方财富正常显示,面板/菜单栏标注来源;
4. **名称**:默认菜单栏仍为「代码 价格」;切换 `namePrice` 立即显示名称;自定义别名生效;隐藏名称生效;
5. **颜色**:国际/中国/自定义三种方案即时生效;自定义颜色持久化,重启应用后保留;
6. **回归**:旧设置(仅 `symbol`/`refreshInterval`/`redUpGreenDown`)的存量用户升级后行为不变;
7. **编译**:`swift build -c release` 通过,CI(pr-check)绿色。

---

## 10. 后续扩展(roadmap,本期不做)

| 方向 | 说明 | 依赖 |
| --- | --- | --- |
| 多股票同时显示 | 东方财富 `ulist.np/get` 已支持批量,菜单栏横向排布多组 | 本期的 Provider 抽象 |
| 菜单栏显示涨跌幅 | 在 `codePrice` 后追加 `(+1.00%)` | 本期 DisplayFormat 扩展占位符即可 |
| 迷你走势图 | 面板内嵌分时/日 K 缩略图 | 新增历史行情接口(Yahoo 已有 `chart` 接口) |
| 通知提醒 | 触及目标价/涨跌幅阈值时系统通知 | 新增阈值设置 |

---

## 附:关键实现约定(备忘)

- 缩放一律走「字段 f59 / 市场默认」两段式解析,禁止硬编码具体数字;
- 所有网络请求复用 Yahoo 现有 `URLSession` 模式(User-Agent、超时 10s);
- 所有新设置项在 `QuoteModel` 集中声明并立即写 `UserDefaults`,与现有风格一致;
- 错误文案统一中文,与 `FetchError` 现有风格一致。
