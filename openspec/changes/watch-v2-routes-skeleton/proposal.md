# watch-v2-routes-skeleton

## Why

Claude Design 给出的 V2 watchOS 设计稿主张「手机主导，手表执行」，主流程精简到 7
屏：`SyncIdle → PlanSynced → SetReady → LiveSet → SetResult → RestV2 → WorkoutDone`。

当前 watch 路由结构是 V1 时代的 14 屏，含 `exercisePicker / weightInput / cmjCountdown / cmjGo / cmjResult / planProgress / planNext / readiness / liveWorkout / rest / summary` 等
混合入口。要实现 V2，**必须先把骨架立起来**：新增 V2 主流程的 5 个路由 case + 占位
view，root view 从 `WatchHomeView` 切到 `SyncIdleView`。

本 change 只立骨架——新屏只是 stub（占位文字 + 「下一步」按钮），不接通业务逻辑、
不删旧屏。目的是让 commit 2-4 的接通 / 视觉 / 清理工作有可依附的脚手架。

## What

- 新增 5 个 `WatchRoute` case：`syncIdle / planSynced / setReady / setResult / workoutDone`
- 新增 5 个占位 view：`SyncIdleView / PlanSyncedView / SetReadyView / SetResultView / WorkoutDoneView`
- `WatchRootView` root 从 `WatchHomeView()` 切到 `SyncIdleView()`
- `WatchRootView.routeView(_:)` switch 加新 case 分支
- `LiveWorkoutController` 暴露两个计算属性供后续 view 读取：
  - `lastSetMetSummary: (status: MetStatus, mv: Double, target: ClosedRange<Double>?)?`
  - `currentRestSeconds: Int`（rename 自 `lastResolvedRest`）

## Impact

- 新增 1 个 capability：`watch-v2-navigation`
- **不删任何路由 / view**——commit 4 才做清理
- **不接通业务流**——commit 2-3 才做
- 改动文件：
  - `VBTrainerWatch Watch App/Views/WatchNavigation.swift`（加 5 case）
  - `VBTrainerWatch Watch App/Views/WatchRootView.swift`（root view + switch）
  - `VBTrainerWatch Watch App/Views/WatchScreens.swift`（加 5 stub view）
  - `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`（暴露两属性）
- 零数据迁移、零新依赖、watchOS 部署目标不变
