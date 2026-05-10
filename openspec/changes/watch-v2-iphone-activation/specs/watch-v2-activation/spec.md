# watch-v2-activation

## Purpose

iPhone → Watch 的「准备训练 + 立即激活」契约，加上 LiveWorkoutController 的崩溃恢复
持久化。

## Requirements

### ConnectivityProtocol

- `ConnectivityKind` SHALL 包含 case `startWorkout`
- `ConnectivityMessage` SHALL 包含 case `startWorkout(WatchPreferencesSnapshot)` ——
  实际 payload 类型 `StartWorkoutSnapshot`
- `StartWorkoutSnapshot` SHALL 是 `Codable & Sendable & Equatable` 的 public struct
  含字段 `templateId: UUID`、`startItemIndex: Int`（默认 0）

### iPhone 推送

- `TemplateSyncService.pushAndStart(template:on:startItemIndex:)` SHALL 先调
  `transferUserInfo` 推 `.template(...)`、再推 `.startWorkout(...)`
- 现有 6 个 `TemplateSyncService.push(template:on:)` 调用站 SHALL 改用 `pushAndStart`：
  - `TodayView.swift:329`、`:333`、`:397-398`
  - `PlanView.swift:551`、`:790`
  - `WeeklyPlanView.swift:457`

### Watch 接收

- `WatchConnectivityService.session(_:didReceiveUserInfo:)` SHALL 处理
  `.startWorkout(snap)`：调用 `WatchActivationCenter.shared.activate(snap)`
- `WatchActivationCenter` SHALL 是 `@MainActor` 单例，暴露：
  - `var pending: StartWorkoutSnapshot?`（@Published）
  - `func activate(_:)`：写入 pending + post `.vbtWatchActivated` notification
  - `func consume() -> StartWorkoutSnapshot?`：读出并清空
- `Notification.Name.vbtWatchActivated` SHALL 在 `Shared/Services/ConnectivityProtocol.swift`
  附近定义为 public 常量

### Watch 导航响应

- `WatchRootView` SHALL 在收到 `.vbtWatchActivated` 通知时：
  - `nav.popToRoot()`
  - `nav.push(.planSynced)`
- 不直接 push `.setReady`（用户在 PlanSynced 视图手动开始）

### 崩溃恢复

- `LiveWorkoutController` SHALL 暴露：
  - `func prepareSet() async`（commit 2 占位 stub；commit 3 实装）
  - `func persistResumeCursor()`：把 `plannedSpecs / plannedSetCursor / currentTemplateId`
    写 `UserDefaults.standard` keys `vbt.live.resume.*`
  - `func restoreFromCursorIfPossible()`：从 UserDefaults 读出，写回内存
  - `func clearResumeCursor()`：UserDefaults removeObject
- `LiveWorkoutController.preparePlanned(item:)` SHALL 在末尾调
  `persistResumeCursor()`
- `LiveWorkoutController.endSet()` SHALL 在 `plannedSetCursor += 1` 之后调
  `persistResumeCursor()`
- `LiveWorkoutController.completeWithFeedback(...)` SHALL 在末尾调
  `clearResumeCursor()`

### 单元测试

- `Tests/AlgorithmTests/StartWorkoutCodecTests.swift`：构造一个
  `ConnectivityMessage.startWorkout(...)` → JSONEncode → JSONDecode → 字段不丢
- `Tests/AlgorithmTests/StartWorkoutCodecTests.swift` 同时验证旧的
  `ConnectivityMessage.template(...)` 在新 enum 下仍能 round-trip（兼容）

## Behaviour

#### Scenario: iPhone 用户在 Today 点「在 Watch 上开始」
- **WHEN** `TodayView` 的「在 Watch 上开始」按钮被点击
- **THEN** iPhone 通过 `pushAndStart(template:on:)` 发出 2 条 transferUserInfo

#### Scenario: Watch app 在前台收到 startWorkout
- **WHEN** `WatchConnectivityService.session(_:didReceiveUserInfo:)` 解出 `.startWorkout(snap)`
- **THEN** `WatchActivationCenter.shared.pending = snap`、`.vbtWatchActivated` 通知发布
- **AND** `WatchRootView` 收到通知后 `nav.popToRoot()` + `nav.push(.planSynced)`

#### Scenario: 训练中 watch app 被系统终止后重启
- **WHEN** `endSet()` 执行后 cursor 写入 UserDefaults
- **AND** watch app 被冷启动
- **THEN** `restoreFromCursorIfPossible()` 把 plannedSpecs + cursor + templateId 读回内存

#### Scenario: 旧版 iPhone build 推送 template
- **WHEN** iPhone 推 `.template` 但**不**推 `.startWorkout`
- **THEN** watch 留在 SyncIdle，用户手动点进 PlanSynced（向后兼容）
