# watch-v2-iphone-activation

## Why

V2 设计稿默认 iPhone 点「在 Watch 上开始」→ Watch 自动从 SyncIdle 跳到主流程。
当前代码只通过 `TemplateSyncService.push` 推 template 到 watch，**没有任何「立即激活」
信号**——watch 收到 template 后只更新 `TodayPlanStore`，不触发导航跳转，用户必须自
己抬腕进 watch app 然后手动从 SyncIdle 点进 PlanSynced。

要让设计稿的体验跑通，必须新增一条「准备 + 激活」消息：iPhone 一次性发送
template + startWorkout 两条消息，watch 收到 startWorkout 后通过通知触发
`WatchNavigation.popToRoot()` + `nav.push(.planSynced)`。

同时，V2 主流程依赖 `LiveWorkoutController` 内的 `plannedSpecs / plannedSetCursor /
currentTemplateId` 状态，actor 在内存里的 cursor 一旦 watch app 被系统冷启动会丢失。
本 change 把恢复点持久化到 UserDefaults，解决「训练中崩溃 / app 被杀后重启」回到正
确位置。

## What

- 新增 `ConnectivityKind.startWorkout` + `WatchPreferencesSnapshot` 同级的
  `StartWorkoutSnapshot { templateId: UUID, startItemIndex: Int }`
- `ConnectivityMessage` 加 `case startWorkout(StartWorkoutSnapshot)`
- `Shared/Services/TemplateSyncService.swift::pushAndStart(template:on:startItemIndex:)`
  helper：先 push template，再 push startWorkout
- iPhone 6 个调用站从 `push(template:on:)` 切到 `pushAndStart(...)`
- `VBTrainerWatch Watch App/Services/WatchConnectivityService.swift`：
  入站 `.startWorkout` 写入新增的 `WatchActivationCenter` + post 通知
- `WatchActivationCenter`（新文件）：watch-side singleton，承接
  startWorkout 事件 + `LiveWorkoutController` 崩溃恢复持久化
- `LiveWorkoutController`：
  - `func prepareSet() async`（首组前 actor 预热的占位入口，commit 3 实装）
  - `persistResumeCursor()` / `restoreFromCursorIfPossible()`
- `WatchRootView` 监听 `.vbtWatchActivated` 通知 → `nav.popToRoot()` + `nav.push(.planSynced)`
- 单测 `Tests/AlgorithmTests/StartWorkoutCodecTests.swift`：`StartWorkoutSnapshot`
  encode → decode round-trip 不丢字段

## Impact

- 新增 capability：`watch-v2-activation`
- 改动文件：
  - `Shared/Services/ConnectivityProtocol.swift`
  - `Shared/Services/TemplateSyncService.swift`
  - `VBTrainer/Views/Today/TodayView.swift`（3 个调用站）
  - `VBTrainer/Views/Plan/PlanView.swift`（2 个调用站）
  - `VBTrainer/Views/Plan/WeeklyPlanView.swift`（1 个调用站）
  - `VBTrainerWatch Watch App/Services/WatchConnectivityService.swift`
  - `VBTrainerWatch Watch App/Services/WatchActivationCenter.swift`（新增）
  - `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`
  - `VBTrainerWatch Watch App/Views/WatchRootView.swift`
  - `Tests/AlgorithmTests/StartWorkoutCodecTests.swift`（新增）
- **跨版本兼容**：旧版 watch（不识别 `.startWorkout` kind）SHALL 在 decoder 处
  silently fall through `default:` 分支，避免崩溃。已现有 `default: break` 处理。
- 零数据迁移、零新依赖、watchOS 部署目标不变
