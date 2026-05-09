# Proposal: EventKit Bidirectional Sync

## Why

PR #2 落地了 iPhone 日历单向写入（VBTrainer → 日历）。Claude Design chat 里你明确诉求"在日历 App 直接拖事件改时间，VBTrainer 也会跟着改"。本 change 补反向同步：日历 → DayPlan。

## What Changes

- **改** `Shared/Services/EventKitService.swift`：
  - 加 `hasReadAccess` 属性 + `requestFullAccess()` 方法（iOS 17+ 用 `requestFullAccessToEvents`）
  - 加 `pullChanges(in: ClosedRange<Date>) -> [EventChange]` 读训练日历的事件快照
  - 加 `subscribeToChanges(_:)` 订阅 `EKEventStoreChanged` 通知
- **新增** `Shared/Services/DayPlanReverseSyncer.swift`：单例 syncer
  - `bind(container:)` 注册订阅 + 持有 ModelContainer
  - `runReconcile()` 拉 ±30 天事件 → 比对 DayPlan.eventKitIdentifier → 更新 date/scheduledTimeMinutes / 删除已 missing 的 plan
  - `vbtDayPlanReverseSynced` 通知供 UI 刷新
- **改** `VBTrainer/App/VBTrainerApp.swift`：app 启动时 `DayPlanReverseSyncer.shared.bind(container:)`
- **改** `VBTrainer/Views/Plan/WeeklyPlanView.swift`：sync options 加 "反向读取" toggle，启用时请求 full access + 立即跑一次 reconcile

## Capabilities

### Modified Capabilities
- `iphone-weekly-planner`（PR #2 capability）— 加反向同步入口

## Impact

- 仅 iOS target；EventKit 已经在 PR #2 引入
- 默认关闭：用户主动 toggle 才请求 full access；旧 write-only 用户不受影响
- DayPlan 有 `eventKitIdentifier` 才会被 reconcile（否则 syncer 跳过）
- 完成的 plan（completed=true）不被反向修改，保护历史
