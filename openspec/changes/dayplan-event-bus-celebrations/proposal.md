# Proposal: DayPlan Event Bus + Celebrations + Weekly Adherence

## Why

Round 2 PM 共识：Round 1 把 status 字段做扎实后，**消费侧**才是关键。状态变化没有订阅机制 = 半截工程。同时第一次解锁了"训完那一秒触发庆祝"和"基于状态聚合的本周叙事"两个高 ROI 落地点。

- 交互角度：训后 30 秒是用户产生"这工具懂我"印象的黄金窗口；CelebrationCard 是这一秒该发生的事
- 系统角度：DayPlan 状态变化必须有单一订阅源 (AsyncStream)，否则未来加 K（实时编辑）/ J（AI 解释）/ V2 AI 复盘 都得回头改契约

合并 D（庆祝）+ E（Stats 叙事）— 都依赖同一套数据。

## What Changes

- **新增** `Shared/Services/DayPlanEventBus.swift`：`AsyncStream<DayPlanEvent>` 单例发布订阅
  - 4 类事件：`completed(planId, workoutId?)` / `inProgress(planId)` / `skipped(planId)` / `missed(planIds)`
- **改** `DayPlanStateMachine`：每个 mutation 完成后 `DayPlanEventBus.shared.publish(...)`
- **改** `DayPlanReverseSyncer`：日历删 → 改走 `DayPlanStateMachine.markSkipped` (而不是直接 mutate)，让事件正常 publish
- **新增** `Shared/Services/WeeklyAdherence.swift`：
  - `WeeklyAdherence` struct: weekStart/weekEnd/planned/completed/skipped/missed/inProgress/current + completionRate + isFullyCompleted
  - `WeeklyAdherenceCalculator.compute(for:context:)`
  - `WeeklyAdherenceCalculator.currentStreak(now:context:)` 计算连续完成天数
- **新增** `VBTrainer/Views/Common/CelebrationCard.swift`：
  - 4 类 Kind：prBeaten / weeklyFullyCompleted / streakMilestone / generic
  - 渐变 accent 卡 + haptic.success + 可滑走/X 关闭 + 6s 自动消失
  - `CelebrationResolver.resolve(completedWorkoutId:context:)` 优先级：PR > 周满训 > streak milestone(3/7/14/30/60/100) > generic
- **改** `VBTrainer/Views/Common/RedesignComponents.swift`：新增 `WeekProgressStrip`（7 dots × status colors）
- **改** `VBTrainer/Views/Today/TodayView.swift`：
  - 加 weekStripCard（在 TodayHeader 与 banner 之间）显示本周完成度 dots + 简短 caption
  - .task 订阅 EventBus；收到 .completed 调 CelebrationResolver → 设 pendingCelebration → 6s 自动消失
  - top overlay 渲染 CelebrationCard
- **改** `VBTrainer/Views/Stats/StatsView.swift`：headline card 顶部加 narrativeLine（一句话叙事："已完成 5/7 · 训练量高于上周 8% · 平均速度更快"）

## Capabilities

### New Capabilities
- `dayplan-event-bus-celebrations`

### Modified Capabilities
- `iphone-today-flow` — 周完成度 strip + Celebration overlay
- `iphone-stats-headline`（PR #2 capability）— 加 narrative line

## Impact

- 仅 iOS 端有 UI 反馈消费；事件 bus 设计为跨平台（Watch 端可订阅但本 change 不接）
- 6s 庆祝持续时间 / streak 里程碑阈值 都是常量，方便后续调
- 不改 SwiftData schema，不改协议
