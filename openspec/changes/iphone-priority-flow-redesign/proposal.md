# Proposal: iPhone Priority Flow Redesign

## Why

Zexi 在 Claude Design 反复迭代后，对 iPhone 端的交互动线下了清晰判断：

> "工具软件就要把最实用的工具放在一开始 — 用户一点进来看见的就是今天的准备分数和动作计划，两个页面内能完成动作计划的提前规划。优先级最高的是『提前规划』，第二高是『历史训练计划回看』，第三高是『历史统计与环比』。"

设计稿（vbt-screens-v4.jsx + VBTrainer.html）落定的 5 步主动线：
**今天 → 开练 → 历史 → 计划 → 统计**。

当前 iOS app 与设计稿的差距：

- **今天**：现实是 ReadinessRing 大卡 + 最近训练摘要 + 频率热力图。设计稿要求 96pt Readiness 圆环 + HRV/睡眠/RHR 三联指标 + 已安排今日 banner（来自计划）+ AI 推荐（紫色卡）+ 我的模板（橙色色条）+ 快速起点。**主屏不再展示 ad-hoc 训练数据**，仅在用户已安排今日训练或主动选模板时才进入 Plan 流程。
- **计划**：现实是 Tab "训练" 下的 NavigationLink form-based TemplateEditor + 简陋月历 plan map。设计稿要求**单屏组装**（顶部摘要 + 起点 chips + 折叠动作卡 + 每组独立调 + sticky CTA Watch · 开始训练 · 日历同步），并且**周计划同步 iPhone 日历**（EventKit）。
- **历史**：现实是 List。设计稿要求 **iOS 原生日历样式**（红色今天圆 / 圆点事件标记）+ 选中日预览卡 + 月内训练列表 + 训练详情用每动作折叠卡（带 mini 速度曲线 + 每组重量/次数/休息/均速/PR 角标）。
- **统计**：现实没有这个 tab。设计稿要求新建 — 头条 "本周 vs 上周" 4 宫格 + e1RM 主项进展 + Readiness 趋势 + PR 列表入口。
- **数据模型**：现实 TemplateItem 只能记录每动作的 "全组同重" 目标。设计稿明确要求 **每组独立调**（不同重量、不同次数、不同休息）。需要新增 TemplateSetSpec。
- **持久化**：现实用 @AppStorage 存日历计划 JSON 字符串。需要换成 SwiftData 的 DayPlan，便于 weekly planner / history dot indicators / EventKit 双向 ID 追踪。

## What Changes

### 数据模型
- **新增** `Shared/Models/DayPlan.swift`：每日安排 = (date, templateId, scheduledTimeMinutes, eventKitIdentifier, completed, completedWorkoutId)
- **新增** `Shared/Models/TemplateSetSpec.swift`：每组规格（warm-up / work · weightKg / reps / restSeconds），cascade 挂在 TemplateItem 下
- **改** `Shared/Models/TemplateItem.swift`：加 `setSpecs: [TemplateSetSpec]` 关系 + 计算属性 `hasPerSetSpecs / orderedSetSpecs / primaryWorkWeightKg / effectiveWorkSetCount`，向下兼容旧的 `targetSets/targetReps/targetWeightKg`
- **改** `Shared/Models/ModelSchema.swift`：登记 DayPlan + TemplateSetSpec

### 服务层
- **新增** `Shared/Services/DayPlanStore.swift`：DayPlan CRUD + 区间查询
- **新增** `Shared/Services/AIRecommendationEngine.swift`：规则化推荐（Readiness < 65 → 减载日 / 距上次最强动作 ≥ 21 天 → PR 重测 / 距上次 CMJ > 7 天 → 神经测试），返回最多 2 张卡
- **新增** `Shared/Services/EventKitService.swift`：iPhone 日历集成（write-only access · "训练" 独立日历 · 30 分钟提醒 · 创建 / 更新 / 删除）
- **新增** `Shared/Services/WeekOverWeekStats.swift`：本周 vs 上周（训练量 / 平均速度 / 平均 VL% / 训练次数）
- **新增** `Shared/Theme/GoalTheme.swift`：根据 TrainingGoal 切换主色（爆发=红 / 力量=橙 / 增肌=紫 / 减脂=蓝 / 综合=靛）+ 默认 VL 警戒

### iPhone 视图
- **改** `VBTrainer/Views/RootView.swift`：4 tabs → **5 tabs**（今天 / 计划 / 历史 / 统计 / 我的）
- **重写** `VBTrainer/Views/Today/TodayView.swift`：TodayHeader（96pt Readiness ring + HRV/睡眠/RHR 三联）+ 已安排 banner（如有）+ AI 推荐横滑卡 + 我的模板列表 + 快速起点 3 宫格
- **新建** `VBTrainer/Views/Plan/`：
  - `PlansListView.swift`（计划 tab 顶层 — 周计划入口 + 模板列表）
  - `PlanView.swift`（单屏编辑器 — 摘要 + 起点 chips + 折叠动作卡 + 每组独立调 + sticky CTA）
  - `WeeklyPlanView.swift`（7 天计划 + iPhone 日历同步）
- **重写** `VBTrainer/Views/History/HistoryView.swift`：iOS 原生日历样式（红色今天 / 圆点事件标记）+ 选中日预览卡 + 月度列表 + 列表/动作 segmented 视图
- **重写** `VBTrainer/Views/History/WorkoutDetailView.swift`：hero 4 项核心数据 + "查看综合时间轴" 入口（横屏）+ 每动作折叠卡（mini 速度曲线 + 每组明细）
- **新建** `VBTrainer/Views/Stats/StatsView.swift`：周环比头条 + e1RM top 3 + Readiness 14 天趋势 + PR 列表
- **新建** `VBTrainer/Views/Common/RedesignComponents.swift`：TodayHeader / SectionHeader / ScheduledTrainingCard / TemplateRowItem / AIRecommendationCard / QuickStartTile / MiniSparkline / IOSCalendarMonth / StartChipsBar
- **新建** `VBTrainer/Views/Common/ExercisePickerSheet.swift`：从原 TemplateEditorView 提出来的复用组件
- **删除**：`Train/PlansView.swift`、`Train/CalendarPlanView.swift`、`Train/TemplateEditorView.swift`、`Train/TemplateItemEditorView.swift`（被新 Plan 流程取代）
- **删除**：`Today/ReadinessRingCard.swift`、`Today/WorkoutSummaryCard.swift`、`Today/TrainingHeatmap.swift`（被 TodayHeader / 已安排 banner / 历史日历取代）

### 配置
- **改** `project.yml`：iOS target 加 `INFOPLIST_KEY_NSCalendarsWriteOnlyAccessUsageDescription` + `INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription`，让 EventKit 能弹权限弹窗

### Watch 协同（已就位，无需改动）
- 既有 `TemplateSyncService.push(template:on:)` 已经能把 TemplateSnapshot 通过 `transferUserInfo` 发给 Watch
- Watch 端 `WatchConnectivityService` 收到 `.template(snap)` → `TodayPlanStore.shared.store(snap)` → `WatchHomeView` 显示 "今日计划：..." 入口
- TodayView "从 Watch 开始" 按钮 + PlanView "开始训练" 按钮 + WeeklyPlanView 任意日 assign + Schedule sheet 都会在保存时调 `TemplateSyncService.push`

## Capabilities

### New Capabilities

- `iphone-today-flow` — 主屏交互（默认 = 模板选择；已安排 = banner CTA）
- `iphone-plan-editor` — 单屏组装编辑器（折叠卡 + 每组独立调 + EventKit + Watch push）
- `iphone-weekly-planner` — 7 天计划 + iPhone 日历同步
- `iphone-history-calendar` — iOS 原生日历样式 + 训练详情卡片化
- `iphone-stats-headline` — 周环比 + e1RM + 趋势

### Modified Capabilities

- `iphone-tab-structure`（当前 4 tabs → 5 tabs）

## Impact

- **iPhone 主体重做**，从入口到详情页全部走新动线
- **Watch 端不变**（TemplateSnapshot 协议 + TodayPlanStore 已就位）
- 新增 EventKit 依赖（仅 iOS）
- 数据模型向下兼容：旧 TemplateItem 没有 setSpecs 时回退到 `targetSets/targetReps/targetWeightKg`
- 模型 schema 新增 2 张表（DayPlan、TemplateSetSpec），SwiftData 自动迁移（仅新增不破坏旧字段）
- 容器是 Linux，编译/真机验证由用户在本机做（macOS）
