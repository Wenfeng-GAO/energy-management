---
date: 2026-06-05
title: "开发文档：睡眠教练 V1.1"
status: draft
source_product_doc: docs/prd/2026-06-05-sleep-coach-v1-1-product-spec.md
source_design_doc: docs/design/2026-06-05-sleep-coach-v1-1-design-spec.md
source_prototype: docs/prototypes/sleep-coach-web-v1-1
---

# 开发文档：睡眠教练 V1.1

## 1. 开发结论

目标不是新增一批零散功能，而是让原生 iOS App 对齐当前 V1.1 原型：

- 修正核心动线。
- 重做关键页面视觉。
- 增加睡觉/起床确认后的情绪动效。
- 报告改为基于手动确认的睡眠窗口。

实现应以这三份材料为准：

- 产品文档：`docs/prd/2026-06-05-sleep-coach-v1-1-product-spec.md`
- 设计文档：`docs/design/2026-06-05-sleep-coach-v1-1-design-spec.md`
- Web 原型：`docs/prototypes/sleep-coach-web-v1-1`

## 2. 当前代码结构

原生 iOS 项目已经存在，核心文件：

```text
EnergyManagement/
├─ ContentView.swift
├─ EnergyManagementApp.swift
├─ DesignSystem/
│  ├─ AppSurface.swift
│  ├─ ColorTokens.swift
│  ├─ PrimaryActionButton.swift
│  ├─ SpacingTokens.swift
│  ├─ StatusBanner.swift
│  └─ TypographyTokens.swift
├─ Models/
│  ├─ AppRoute.swift
│  ├─ NotificationStatus.swift
│  ├─ ReportSummary.swift
│  ├─ SleepRecord.swift
│  └─ SleepSchedule.swift
├─ Services/
│  ├─ NotificationPermissionService.swift
│  ├─ NotificationRouteResolver.swift
│  ├─ SleepDataStore.swift
│  ├─ SleepNotificationScheduler.swift
│  ├─ SleepReportCalculator.swift
│  └─ WakeWindowPolicy.swift
├─ ViewModels/
│  ├─ BedtimeViewModel.swift
│  ├─ HomeViewModel.swift
│  ├─ ReportsViewModel.swift
│  ├─ SetupViewModel.swift
│  └─ WakeViewModel.swift
└─ Views/
   ├─ Bedtime/BedtimePreparationView.swift
   ├─ Home/HomeView.swift
   ├─ Reports/
   ├─ Setup/
   └─ Wake/
```

已有测试：

- 单元测试：`EnergyManagementTests/`
- UI 测试：`EnergyManagementUITests/`
- 最近一次完整 Xcode 验收：`docs/acceptance/xcode-validation.md`

## 3. 原型到 iOS 的映射

| 原型状态 | iOS 目标文件 | 说明 |
| --- | --- | --- |
| onboarding | `Views/Setup/OnboardingView.swift` | 首次进入介绍页 |
| setup / setupEdit | `Views/Setup/ScheduleSetupView.swift`、`ViewModels/SetupViewModel.swift` | 首次设置和修改作息 |
| home | `Views/Home/HomeView.swift`、`ViewModels/HomeViewModel.swift` | 今日睡眠首页 |
| bedtime | `Views/Bedtime/BedtimePreparationView.swift`、`ViewModels/BedtimeViewModel.swift` | 睡前准备 tips 和「我睡觉了」 |
| sleepDone | 新增或扩展 Bedtime 完成状态视图 | 睡觉确认后的安静结束动效 |
| wake | `Views/Wake/WakeConfirmationView.swift`、`ViewModels/WakeViewModel.swift` | 起床确认 |
| wakeDone | `Views/Wake/WakePromptsView.swift` | 起床确认后的唤起动效和提示 |
| report | `Views/Reports/ReportsView.swift`、`DailyReportCard.swift`、`SevenDayTrendView.swift` | 今日报告 |

## 4. 数据模型要求

### 4.1 SleepSchedule

需要支持：

- 睡觉时间。
- 起床时间。
- 睡前准备提前分钟数。
- 提醒开关。

规则：

- 修改作息后保存为当前 active schedule。
- 调度通知时使用当前 schedule。
- 历史记录应保留当日 schedule snapshot，避免改作息后历史报告漂移。

### 4.2 SleepRecord

建议字段：

- localDate。
- scheduledBedtime。
- scheduledWakeTime。
- prepLeadMinutes。
- sleepConfirmedAt，可为空。
- wakeConfirmedAt，可为空。
- completionState。

规则：

- 点击「我睡觉了」写入 `sleepConfirmedAt`。
- 点击「我起床了」写入 `wakeConfirmedAt`。
- 同一天重复点击时，应明确覆盖策略。MVP 推荐：保留第一次确认，后续不重复出现确认按钮；开发调试可重置。

### 4.3 ReportSummary

需要输出：

- sleepWindowText。
- sleepConfirmedText。
- wakeConfirmedText。
- targetBedtimeText。
- targetWakeText。
- dataCompleteness。
- sevenDayTrend。
- disclaimer 文案。

报告文案必须包含边界：这是手动确认形成的睡眠窗口，不是医学睡眠时长。

## 5. 路由与状态

建议 AppRoute 至少表达：

```text
onboarding
setup
home
bedtimePreparation
sleepComplete
wakeConfirmation
wakeComplete
report
```

关键状态转换：

```text
onboarding --开始设置--> setup
setup --保存--> home
home --修改作息--> setup(editing)
home --睡前准备--> bedtimePreparation
bedtimePreparation --我睡觉了--> sleepComplete
home --起床确认--> wakeConfirmation
wakeConfirmation --我起床了--> wakeComplete
wakeComplete --查看今日报告--> report
home --查看报告--> report
```

通知点击路由：

```text
bedtime notification -> bedtimePreparation
wake notification -> wakeConfirmation
stale / unknown notification -> home
```

## 6. 通知实现

服务：

- `NotificationPermissionService`
- `SleepNotificationScheduler`
- `NotificationRouteResolver`

实现要求：

- 保存或修改作息后重新调度通知。
- 睡前准备通知时间 = 睡觉时间 - 提前量。
- 起床通知时间 = 起床时间。
- 关闭提醒后取消未来通知。
- 权限被拒绝时，不阻塞核心使用，只显示低噪声状态。

测试要求：

- 睡觉 23:30、提前 45 分钟，调度 22:45。
- 起床 07:30，调度 07:30。
- 修改时间后旧通知被替换。
- 关闭提醒后不调度。
- 通知 tap 能解析到正确 AppRoute。

## 7. 页面实现要求

### 7.1 OnboardingView

对齐原型：

- 标题：建立一个安静、稳定的睡眠节律。
- 正文：好的睡眠节律，会让身体更容易恢复，也让第二天醒来时多一点清醒和掌控感。
- 主按钮：开始设置。

不得出现：

- 版本号。
- 英文 kicker。
- 功能列表。

### 7.2 ScheduleSetupView

对齐原型：

- 睡觉时间。
- 起床时间。
- 睡前准备提前量。
- 提醒开关。
- 首次按钮：保存并进入首页。
- 编辑按钮：保存修改。

提醒开关不要使用系统 checkbox 视觉；应使用设计系统内的自定义 row + switch。

### 7.3 HomeView

对齐原型：

- 标题：今日睡眠。
- 两个时间面板：睡觉、起床。
- 文案：睡前准备 HH:mm 开始。提醒已计划 / 提醒未开启。
- 操作：修改作息、睡前准备、起床确认、查看报告。

注意：

- 首页不要用大段文字解释接下来会发生什么。
- 后续可优化为根据当前时间突出主行动，但 V1.1 先对齐原型。

### 7.4 BedtimePreparationView

对齐原型：

- 深色夜间背景。
- 标题：睡前准备。
- 正文：距离睡觉时间还有 X 分钟。先把环境调到更容易入睡的状态。
- 三条 tips：
  - 降低光线刺激。
  - 让卧室安静、偏凉、偏暗。
  - 避开临睡前刺激。
- 底部主按钮：我睡觉了。

注意：

- 不做 checkbox checklist。
- 不出现「我开始准备了」。
- 主按钮高度要比普通主按钮更大。

### 7.5 SleepComplete 状态

点击「我睡觉了」后进入。

要求：

- 后台保存睡觉确认时间。
- 标题：可以安心睡了。
- 正文：今天到这里就好。把手机放远一点，让身体慢慢进入休息。
- 显示明早起床时间。
- 有收束呼吸圆动效。

动效：

- 圆环从稍大状态收束。
- 中心圆轻微缩小并稳定。
- 内容轻微上浮出现。
- Reduce Motion 开启时禁用或弱化。

### 7.6 WakeConfirmationView

要求：

- 标题：早安。
- 正文保持简短。
- 主按钮：我起床了。
- 不要求用户先看报告。

### 7.7 WakePromptsView / WakeComplete 状态

点击「我起床了」后进入。

要求：

- 后台保存起床确认时间。
- 标题：开始清醒。
- 正文：先做一件小事，让身体比手机先醒来。
- 提示：
  - 喝几口水。
  - 拉开窗帘，让房间变亮。
  - 站起来活动一分钟。
- 主按钮：查看今日报告。
- 次按钮：回到首页。
- 有晨光唤起动效。

动效：

- 太阳从下方进入。
- 光圈扩散淡出。
- 内容轻微上浮。
- Reduce Motion 开启时禁用或弱化。

### 7.8 ReportsView

要求：

- 标题：今日睡眠报告。
- 第一视觉：睡眠窗口，例如 `8 小时 6 分钟`。
- 说明：这是昨晚手动确认形成的睡眠窗口，不是医学睡眠时长。
- 指标：昨晚睡觉、今早起床、目标睡觉、目标起床。
- 七日节律趋势。
- 缺失数据时显示待完整状态。

## 8. 设计系统实现

建议优先修改：

- `ColorTokens.swift`
- `TypographyTokens.swift`
- `SpacingTokens.swift`
- `PrimaryActionButton.swift`
- `AppSurface.swift`

Token 目标：

- warm rice background。
- warm paper surface。
- dark warm ink。
- muted warm gray。
- sage accent。
- night surface。
- morning surface。

组件目标：

- 主按钮支持普通高度和 sleep-action 高度。
- 次级胶囊按钮支持 action row。
- 表单 row 支持说明文案。
- 状态图形应可作为 SwiftUI Shape / View 实现，不引入图片资产。

## 9. 测试计划

### 9.1 单元测试

需要覆盖：

- 睡前准备时间计算。
- 跨午夜睡眠窗口计算。
- 缺失确认时报告状态。
- 保存/修改作息。
- 通知调度时间。
- 通知路由。
- wake window 策略，如果当前实现仍保留窗口。

### 9.2 UI 测试

关键路径：

```text
首次打开
  -> 开始设置
  -> 保存并进入首页
  -> 修改作息
  -> 保存修改
  -> 睡前准备
  -> 我睡觉了
  -> 可以安心睡了
  -> 回到首页
  -> 起床确认
  -> 我起床了
  -> 开始清醒
  -> 查看今日报告
```

断言：

- 核心按钮存在且可点击。
- 页面不出现英文 kicker。
- 睡前准备页不出现「我开始准备了」。
- 睡觉后页面不突出「已记录」。
- 起床后页面不出现「已记录」。
- 报告显示 `8 小时 6 分钟` 类似睡眠窗口。

### 9.3 视觉验收

至少验证：

- iPhone 16e / 默认字号。
- 小屏设备或较大 Dynamic Type。
- 深色睡前页按钮不被遮挡。
- 起床页主按钮不被遮挡。
- Reduce Motion。

参考状态图：

- `docs/prototypes/sleep-coach-web-v1-1/screenshots/01-onboarding.png`
- `docs/prototypes/sleep-coach-web-v1-1/screenshots/02-setup.png`
- `docs/prototypes/sleep-coach-web-v1-1/screenshots/03-home.png`
- `docs/prototypes/sleep-coach-web-v1-1/screenshots/04-bedtime-preparation.png`
- `docs/prototypes/sleep-coach-web-v1-1/screenshots/05-sleep-complete.png`
- `docs/prototypes/sleep-coach-web-v1-1/screenshots/06-wake-confirmation.png`
- `docs/prototypes/sleep-coach-web-v1-1/screenshots/07-wake-complete.png`
- `docs/prototypes/sleep-coach-web-v1-1/screenshots/08-daily-report.png`

## 10. 验证命令

优先使用 Build iOS Apps / XcodeBuildMCP 验收。

若使用本地命令，可参考：

```sh
xcodebuild \
  -project /Users/hengzhuo/Documents/energy-management/EnergyManagement.xcodeproj \
  -scheme EnergyManagement \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  test
```

Web 原型验证：

```sh
npm run prototype:sleep-coach
```

打开：

```text
http://localhost:5174
```

## 11. 实施顺序

### Step 1：锁定设计系统

目标：

- 先把颜色、字体、间距、按钮和页面背景调到 V1.1 方向。

验收：

- Onboarding / Home / Setup 不再像基础 SwiftUI 表单。

### Step 2：修正作息设置与首页动线

目标：

- 首次设置和修改作息稳定可用。
- 首页有所有关键入口。

验收：

- 用户不会被困在首次设置后无法修改。

### Step 3：实现睡前准备与睡觉确认

目标：

- 睡前 tips。
- 「我睡觉了」。
- SleepComplete 动效页。
- 保存睡觉确认时间。

验收：

- 睡前动线从提醒到确认完整。

### Step 4：实现起床确认与唤起页

目标：

- 「我起床了」。
- WakeComplete 动效页。
- 保存起床确认时间。
- 清醒提示。

验收：

- 起床动线完整，不再只是状态说明。

### Step 5：实现报告

目标：

- 基于手动确认计算睡眠窗口。
- 缺失数据时不伪造报告。
- 七日趋势轻量展示。

验收：

- 完整记录显示睡眠窗口。
- 不完整记录显示克制提示。

### Step 6：通知与路由收口

目标：

- 调度睡前准备和起床通知。
- 通知点击进入对应页面。
- 修改作息后重新调度。

验收：

- 单元测试覆盖调度和路由。
- 模拟器可验证通知注册逻辑。

### Step 7：可访问性与最终验收

目标：

- Dynamic Type。
- Reduce Motion。
- UI 测试。
- XcodeBuildMCP 完整测试。

验收：

- 自动化测试通过。
- 人工按产品文档关键路径走通。

## 12. 风险

- 现有 native 代码可能已经实现了部分第一版逻辑，直接修补容易留下旧体验。实现时要以 V1.1 原型为准。
- 通知真实体验依赖系统权限和真机环境，模拟器只能覆盖部分。
- 动效如果过重，会破坏极简气质；实现时宁可轻一点。
- 报告语言必须避免医学承诺。

## 13. Definition of Done

- 产品文档中的 US-001 到 US-006 全部满足。
- 设计文档 8 张状态图对应的 native 页面都可在模拟器看到。
- 「我睡觉了」「我起床了」点击后都有可感知但克制的动效。
- 报告使用手动确认时间计算睡眠窗口。
- 不出现英文 kicker。
- 不出现「我开始准备了」。
- 不在确认后突出“已记录”。
- 单元测试和 UI 测试通过。
- Build iOS Apps / XcodeBuildMCP 验收通过。

