## 1. 模型层
- [x] 1.1 `Shared/Models/Enums.swift` 加 `DayPlanStatus`
- [x] 1.2 `Shared/Models/DayPlan.swift` 加 `statusRaw / statusUpdatedAt / status` 计算属性 + setter 同步 `completed`

## 2. 服务层
- [x] 2.1 新增 `Shared/Services/DayPlanStateMachine.swift`（markCompleted / markInProgress / markSkipped / reconcileMissed / backfillLegacyCompleted）
- [x] 2.2 改 `iPhoneConnectivityService`：落库后调 markCompleted
- [x] 2.3 改 `DayPlanReverseSyncer`：日历删 → markSkipped 而非 delete
- [x] 2.4 改 `VBTrainerApp.init`：cold launch 跑 backfill + reconcile

## 3. UI 层
- [x] 3.1 `ScheduledTrainingCard` 升级为状态驱动（status / summary / Theme 内部表）
- [x] 3.2 `TodayView` banner section title + handlePrimary/Secondary 路由
- [x] 3.3 `TodayView` 加 pendingWorkoutDetail 路由（看复盘）
- [x] 3.4 `HistoryView.dotMarkers` 用 status 过滤

## 4. 编译/验证（用户 macOS 本机）
- [ ] 4.1 `xcodegen generate` + `xcodebuild iOS / watchOS`
- [ ] 4.2 真机：完成训练后 Today banner 自动切换为「今日已完成 + mini summary」+「看复盘」
