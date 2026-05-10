# Tasks

## Route enum

- [ ] 在 `VBTrainerWatch Watch App/Views/WatchNavigation.swift::WatchRoute` 加 5 个 case：
  - [ ] `syncIdle / planSynced / setReady / setResult / workoutDone`
  - [ ] 每个 case 的 `id` 返回唯一字符串

## Root view

- [ ] `VBTrainerWatch Watch App/Views/WatchRootView.swift`：
  - [ ] root view 改为 `SyncIdleView()`
  - [ ] `routeView(_:)` switch 加 5 个新 case 分支

## Stub views

- [ ] 在 `VBTrainerWatch Watch App/Views/WatchScreens.swift` 末尾或合适位置新增 5 个 stub view
  - [ ] `SyncIdleView`：「等待手机」+ Button「下一步 PlanSynced」
  - [ ] `PlanSyncedView`：「计划已同步」+ Button「下一步 SetReady」
  - [ ] `SetReadyView`：「本组准备」+ Button「下一步 LiveSet (旧)」
  - [ ] `SetResultView`：「本组结果」+ Button「下一步 RestV2 (旧)」
  - [ ] `WorkoutDoneView`：「训练完成」+ Button「popToRoot」

## Controller 暴露

- [ ] `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`：
  - [ ] 新增计算属性 `var lastSetMetSummary: (status: MetStatus, mv: Double, target: ClosedRange<Double>?)?`
  - [ ] rename + 公开 `lastResolvedRest` 为 `currentRestSeconds: Int`（保留旧名为别名以兼容）

## 验证

- [ ] `./scripts/verify.sh` 通过
- [ ] watch target build 通过（不依赖签名）
- [ ] 真机：app 启动看到 SyncIdle 占位屏，能 step-through 5 个新屏
