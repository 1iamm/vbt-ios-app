## 1. HealthKit Authorization & Background Mode

- [x] 1.1 创建 `Shared/Services/HealthKitAuthorization.swift`：`enum HealthKitAuthorization`，static func `requestWorkoutAuthorization() async throws`，请求 share `[workoutType, activeEnergyBurned]` + read `[heartRate, activeEnergyBurned, workoutType]`
- [x] 1.2 改 `VBTrainerWatch Watch App/App/VBTrainerWatchApp.swift`：在 `init` 里 `Task { try? await HealthKitAuthorization.requestWorkoutAuthorization() }`
- [x] 1.3 改 `project.yml` watch target：加 `INFOPLIST_KEY_WKBackgroundModes: ["workout-processing"]`
- [ ] 1.4 跑 `xcodegen generate`（用户在本机执行 — 容器是 Linux 没有 xcodegen）
- [ ] 1.5 编译 watch + iOS 两个 target，全部 SUCCEEDED（用户在本机 xcodebuild）

## 2. LiveWorkoutController Bridge

- [x] 2.1 创建 `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`：`@MainActor final class LiveWorkoutController: ObservableObject`
- [x] 2.2 内部持 `private var session = ActiveWorkoutSession()`（var，因 actor.events stream 在 complete 后 finish，下次训练需要重建）、`private var consumerTask: Task<Void, Never>?`
- [x] 2.3 `@Published` 字段：`rep / velocity / vlPercent / heartRate / metStatus / lastSetSnapshot / completedSets / heartRateSamples / isRunning / isCompleted / errorMessage`
- [x] 2.4 `func start(...)` 调 `session.start(...)` + 启动 consumerTask 消费 `session.events`；idempotent（isRunning 时 no-op）；调用前 `resetForNewWorkout()` 重建 session
- [x] 2.5 事件映射函数 `public func apply(_ event: ActiveWorkoutSession.SessionEvent)`：`.repCompleted` / `.heartRate` / `.setEnded` / `.sessionEnded` 覆盖；`.stateChanged` / `.vlCeilingExceeded` / `.restTick` 暂忽略（VL 警戒线 UI 留给后续 Tweaks 接入 change）
- [x] 2.6 `func endSet() async`、`func startNextSet(...) async`、`func complete() async -> WorkoutSnapshot`、`func cancel() async`；保存 `currentExerciseId / currentWeightKg / currentVelocityVariant / currentTargetRange / currentVLCeiling / currentSide` 供 Rest "下一组" 复用
- [x] 2.7 `deinit` 取消 consumerTask
- [x] 2.8 暴露聚合属性 `totalReps / avgVelocity / avgVLPercent / avgHeartRate` 供 Summary 直接读

## 3. Wire WatchLiveWorkoutView

- [x] 3.1 改 `WatchLiveWorkoutView`（`VBTrainerWatch Watch App/Views/WatchScreens.swift`）：删除硬编码 `@State` rep / velocity / heartRate / status / vlPercent
- [x] 3.2 controller 改在 `WatchRootView` 持有为 `@StateObject` 并注入 environment（让 Live / Rest / Summary 共享同一实例，避免 NavigationStack push 后丢失）；LiveWorkoutView 用 `@EnvironmentObject var controller`
- [x] 3.3 加 `@State private var didPushToChild = false`（防 onDisappear 误触发 cancel；push 到 Rest 也会让 Live disappear）
- [x] 3.4 body 用 `.task` 调 `controller.start(exerciseId:, weightKg:)`，其他参数走 controller 默认（mv / nil / nil / both / 90s）
- [x] 3.5 把所有 UI 数字 bind 到 `controller.*`；velocityColor 用 `controller.metStatus`
- [x] 3.6 "结束本组" 按钮：`Task { await controller.endSet(); didPushToChild = true; nav.push(.rest(secondsRemaining: 90)) }`
- [x] 3.7 加 `.onDisappear { if !didPushToChild { Task { await controller.cancel() } } }`
- [x] 3.8 errorMessage 非空时显示红色文字提示（不阻断 UI）

## 4. Wire WatchSummaryView & WatchRestView

- [x] 4.1 改 `WatchSummaryView`：删除 `totalReps / avgVelocity / avgVL / avgHR` 默认参数
- [x] 4.2 改用 `@EnvironmentObject var controller: LiveWorkoutController` 读取数据
- [x] 4.3 直接读 `controller.totalReps / avgVelocity / avgVLPercent / avgHeartRate`（计算属性已在 controller 暴露）
- [x] 4.4 "完成" 按钮：`Task { let snap = await controller.complete(); WatchConnectivityService.shared.send(message: .workoutSnapshot(snap)); nav.popToRoot() }`
- [x] 4.5 改 `WatchRestView`：加 `@EnvironmentObject var controller`；"下一组" 按钮调 `controller.startNextSet(weightKg: controller.currentWeightKg, ...)` 后 `nav.pop()`（让多组训练真正衔接，不只是 nav 操作）
- [x] 4.6 environment 通过 `WatchRootView` 注入到整个 NavigationStack，无需 fallback

## 5. Unit Tests

跳过：`LiveWorkoutController` 持 `ActiveWorkoutSession`（watchOS-only actor，依赖
`MotionManager` / `HKWorkoutSession`），iOS Tests bundle 不能 import；为了测试把
`SessionEvent` 提到 Shared 会扩散重构。按 CLAUDE.md 约定 "算法写单测，UI 不写"，
controller 是 UI 桥接，本 change 不补单测，依赖真机验证（见 §6.6）。

下次 change 如果需要单测 controller，方案：把 `ActiveWorkoutSession.SessionEvent`
提到 `Shared/Algorithms/SessionEvent.swift` 作为独立 enum，加 protocol
`SessionEventSource`，controller 接 protocol，单测注入 mock。

## 6. 编译与 OpenSpec 收尾

- [ ] 6.1 重跑 `xcodegen generate`（每次改 project.yml 或新增 .swift 文件后；用户在 macOS 本机执行）
- [ ] 6.2 编译 watch target → BUILD SUCCEEDED（用户）
- [ ] 6.3 编译 iOS target → BUILD SUCCEEDED（用户）
- [ ] 6.4 commit + push 到 `claude/review-project-alignment-t2lp0`
- [ ] 6.5 开 PR
- [ ] 6.6 真机验证（用户做）：心率真实、reps 递增、iPhone 收到 Workout
