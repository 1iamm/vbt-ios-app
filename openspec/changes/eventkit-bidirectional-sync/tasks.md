## 1. Service 层
- [x] 1.1 `EventKitService.hasReadAccess` + `requestFullAccess()`
- [x] 1.2 `pullChanges(in:)` 拉训练日历事件快照
- [x] 1.3 `subscribeToChanges(_:)` 订阅 EKEventStoreChanged

## 2. Syncer
- [x] 2.1 新建 `DayPlanReverseSyncer.swift`（单例 + bind + runReconcile）
- [x] 2.2 比对 eventKitIdentifier → 更新 / 删除 DayPlan
- [x] 2.3 跳过 completed plan
- [x] 2.4 发 `vbtDayPlanReverseSynced` 通知

## 3. 集成
- [x] 3.1 `VBTrainerApp.init` 调 `DayPlanReverseSyncer.shared.bind(container:)`
- [x] 3.2 `WeeklyPlanView` 加 "反向读取" toggle，requestFullAccess + 立即 reconcile

## 4. 编译/验证（用户在 macOS 本机）
- [ ] 4.1 `xcodebuild` iOS target 通过
- [ ] 4.2 真机：开同步写入 → 在 iPhone 日历 App 拖事件改时间 → 回 VBTrainer 周计划列表里时间已变；删除事件 → DayPlan 消失
