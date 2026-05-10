# Tasks

## ConnectivityProtocol 扩展

- [ ] `Shared/Services/ConnectivityProtocol.swift`：
  - [ ] 加 `case startWorkout` 到 `ConnectivityKind`
  - [ ] 加 `public struct StartWorkoutSnapshot: Codable, Sendable, Equatable`，字段
        `templateId: UUID`、`startItemIndex: Int = 0`
  - [ ] 加 `case startWorkout(StartWorkoutSnapshot)` 到 `ConnectivityMessage`，
        `kind` switch 加分支
  - [ ] 加 `public static let vbtWatchActivated = Notification.Name("vbt.watchActivated")`
        到 `Notification.Name` extension

## iPhone 端推送

- [ ] `Shared/Services/TemplateSyncService.swift`：
  - [ ] 加 `public static func pushAndStart(template:on:startItemIndex:)` 先 push
        `.template`，再 push `.startWorkout`
- [ ] `VBTrainer/Views/Today/TodayView.swift`：3 处 `TemplateSyncService.push` 改为
      `pushAndStart`
- [ ] `VBTrainer/Views/Plan/PlanView.swift`：2 处改造
- [ ] `VBTrainer/Views/Plan/WeeklyPlanView.swift`：1 处改造

## Watch 端接收

- [ ] 新建 `VBTrainerWatch Watch App/Services/WatchActivationCenter.swift`：
  - [ ] `@MainActor public final class WatchActivationCenter: ObservableObject`
  - [ ] `public static let shared = WatchActivationCenter()`
  - [ ] `@Published public private(set) var pending: StartWorkoutSnapshot?`
  - [ ] `public func activate(_:)` + `public func consume() -> StartWorkoutSnapshot?`
- [ ] `VBTrainerWatch Watch App/Services/WatchConnectivityService.swift`：
  - [ ] `case .startWorkout(let snap)` → `WatchActivationCenter.shared.activate(snap)`
- [ ] `VBTrainerWatch Watch App/Views/WatchRootView.swift`：
  - [ ] `.onReceive(NotificationCenter.default.publisher(for: .vbtWatchActivated))`
        → `nav.popToRoot()` + `nav.push(.planSynced)`

## LiveWorkoutController 持久化

- [ ] `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`：
  - [ ] `func prepareSet() async`（占位 stub，调 `start(...)` 同样的入口；commit 3 完整实装）
  - [ ] `func persistResumeCursor()`、`func restoreFromCursorIfPossible()`、
        `func clearResumeCursor()`
  - [ ] `preparePlanned(item:)` 末尾调 `persistResumeCursor()`
  - [ ] `endSet()` 末尾调 `persistResumeCursor()`
  - [ ] `completeWithFeedback(...)` 末尾调 `clearResumeCursor()`

## 单元测试

- [ ] 新建 `Tests/AlgorithmTests/StartWorkoutCodecTests.swift`
  - [ ] test_startWorkoutMessage_roundTrips
  - [ ] test_templateMessage_roundTripsAfterStartWorkoutAdded（兼容）

## 验证

- [ ] `./scripts/verify.sh` 通过
- [ ] watch + iPhone target build 通过
- [ ] 单元测试不 regression
