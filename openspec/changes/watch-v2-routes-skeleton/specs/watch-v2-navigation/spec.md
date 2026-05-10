# watch-v2-navigation

## Purpose

V2 主流程的路由骨架。定义 5 个新增 `WatchRoute` case 的语义、转移规则与对应 view
存在性，让后续 commit 的视觉 / 接通工作有契约可依附。

## Requirements

### Route enum

- `WatchRoute` SHALL 包含以下 V2 case（与现有 V1 case 共存）：
  - `syncIdle` —— root 的等待态，无 associated value
  - `planSynced` —— 计划清单态，无 associated value
  - `setReady` —— 单组准备态，无 associated value（数据从 controller 读）
  - `setResult` —— 单组结果态，无 associated value
  - `workoutDone` —— 整次训练完成态，无 associated value
- 每个新 case 的 `id: String` SHALL 返回唯一字符串（用于 NavigationStack 去重）

### Root view

- `WatchRootView` 的 NavigationStack root SHALL 是 `SyncIdleView()`
- 旧 `WatchHomeView` 仍可通过 push 路径访问（commit 4 才彻底清理）

### Stub view 存在性

- `SyncIdleView / PlanSyncedView / SetReadyView / SetResultView / WorkoutDoneView`
  SHALL 在 `WatchScreens.swift` 中定义为可独立编译的 `View` struct
- 每个 stub view 的 body SHALL 至少包含一个能跳到下一屏的 Button，用于真机调试
  时手动 step through 主流程
- Stub view SHALL **不**绑定 controller 状态、不发起数据请求、不自动跳转

### Controller 暴露

- `LiveWorkoutController` SHALL 暴露公共计算属性 `lastSetMetSummary`，类型
  `(status: MetStatus, mv: Double, target: ClosedRange<Double>?)?`，从最近一组
  `completedSets.last` 派生
- `LiveWorkoutController` SHALL 暴露公共属性 `currentRestSeconds: Int`（rename 自
  现有 `lastResolvedRest`，对外契约名）

## Behaviour

#### Scenario: 用户首次启动 watch app
- **WHEN** app 启动
- **THEN** root 显示 `SyncIdleView`，不再是 `WatchHomeView`

#### Scenario: 真机 step-through V2 主流程骨架
- **WHEN** 用户依次点 SyncIdle → PlanSynced → SetReady → 旧 LiveWorkout → SetResult → RestV2 占位 → WorkoutDone 的「下一步」按钮
- **THEN** 路由能依次 push 不报错，每屏占位文字正确显示

#### Scenario: 既有 V1 流程不破坏
- **WHEN** 旧代码路径 push `.exercisePicker / .weightInput / .planProgress` 等老 case
- **THEN** view 仍能正常渲染（commit 4 才删）
