# Proposal: Wire Watch Live Session

## Why

真机首次测试 Watch 训练发现：心率/速度显示是固定假数据，做动作不计 Rep，结束训练 iPhone 也收不到任何数据。

排查后定位：底层全部已实装且正确（`ActiveWorkoutSession` actor、`MotionManager` HKWorkoutSession 包装、`WatchConnectivityService.transferUserInfo`、iPhone 端 `WorkoutStore.save` 落库），唯一缺口是 **Watch UI 层从未持有 / 启动 / 订阅 `ActiveWorkoutSession`**。`WatchLiveWorkoutView` 是壳子，硬编码 `@State` 假值；`WatchSummaryView` 的 "完成" 按钮只 `popToRoot()`，未调 `complete()`、未发 `WCSession`。

另外两个会让真机就算接上链路也跑不通的基础设施缺陷：
1. 从未调 `HKHealthStore.requestAuthorization` → `HKWorkoutSession` 创建会失败
2. watch target 缺 `WKBackgroundModes: workout-processing` → 用户放下手腕系统会挂起采样

## What Changes

- **新建** `Shared/Services/HealthKitAuthorization.swift`：在 app 启动时申请 workout / 心率 / energy 权限
- **改** `VBTrainerWatchApp.init`：触发授权请求
- **改** `project.yml` watch target：添加 `INFOPLIST_KEY_WKBackgroundModes: workout-processing`
- **新建** `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`：`@MainActor ObservableObject`，桥接 `ActiveWorkoutSession` actor 的 AsyncStream 到 SwiftUI `@Published` 字段
- **改** `WatchLiveWorkoutView`：删除硬编码 `@State`，持有 `LiveWorkoutController`，`.task` 启动 session，`.onDisappear` 释放
- **改** `WatchSummaryView` 与 `WatchRestView`：通过 environment 共享同一个 controller，"完成" 按钮调 `controller.complete()` 后通过 `WatchConnectivityService.shared.send(.workoutSnapshot(snap))` 同步给 iPhone
- **新建** `Tests/AlgorithmTests/LiveWorkoutControllerTests.swift`：验证 controller 接收 mock 事件后 `@Published` 字段正确更新

零算法改动、零协议改动，只做"接通"。

## Capabilities

### New Capabilities

- `watch-live-workout`: Watch 实时训练页面与 `ActiveWorkoutSession` 之间的数据流契约（UI 启动 / 订阅 / 终结 session 的规则）

### Modified Capabilities

（无 —— 既有的 `active-workout-session` / `motion-capture` / `heart-rate-capture` capabilities 的实现不变；本 change 仅消费它们）

## Impact

- 仅 watchOS target + 一个 Shared/Services 工具
- 无第三方依赖
- iPhone target 不动（接收侧已就位）
- `project.yml` 改后需重跑 `xcodegen generate`
- 真机首次启动会弹一次 HealthKit 授权弹窗（用户体验改进）
