# watch-v2-edge-cases-cleanup

## Why

设计稿没画但工程层必须考虑的边缘场景，加上 V1 死代码清理：

1. **VLStopWarning 是孤儿路由**——`LiveWorkoutController.apply(.vlCeilingExceeded)`
   当前是 `break`，view 永远不会被 push。本 commit 接通：触发时 post 通知 → root
   监听 → push 路由。
2. **单边动作（左/右臂）**设计稿完全没画，但 `currentSide` 已实装。SetReady
   屏加一个小标签 chip 显示「左侧 / 右侧」（双边时不显示）。
3. **V1 死代码清理**：
   - WatchHomeView / WatchExercisePickerView / WatchWeightInputView 删除
   - WatchPlanProgressView / WatchPlanNextView 删除
   - WatchCMJCountdownView / WatchCMJGoView / WatchCMJResultView 删除（V2 决定 CMJ
     全部移到 iPhone；watch CMJ 三屏将来 iPhone-driven 流程做好后另开 change 重做）
   - WatchReadinessView 拿掉「CMJ 测试」按钮（V2 主流程不再触发）
   - WatchRoute 枚举删 `cmjCountdown / cmjGo / cmjResult / planProgress / planNext / exercisePicker / weightInput`
4. **VL 触发单测**：`Tests/AlgorithmTests/LiveWorkoutControllerVLTests.swift`
   验证 `.vlCeilingExceeded` 事件 → `.vbtVLCeilingExceeded` 通知发布。

## What

- `LiveWorkoutController.apply(.vlCeilingExceeded)` 改成 post 通知
- 新增 `Notification.Name.vbtVLCeilingExceeded`（payload: `["vl": Double, "threshold": Double]`）
- `WatchRootView` 监听该通知 → `nav.push(.vlStopWarning(vl, threshold))`
- `SetReadyView` 加 side chip
- 删 7 个 V1 view struct（共约 600 行死代码）
- 删 7 个 V1 route case（同步 routeView switch）
- 调用 V1 路由的所有外部站点改为合理替代（多数已被 commit 1-3 修掉）
- 单测 `LiveWorkoutControllerVLTests`

## Impact

- 新增 capability：`watch-v2-edge-cases`
- 改动文件：
  - `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`
  - `VBTrainerWatch Watch App/Views/WatchRootView.swift`
  - `VBTrainerWatch Watch App/Views/WatchNavigation.swift`
  - `VBTrainerWatch Watch App/Views/WatchScreens.swift`
  - `Shared/Services/ConnectivityProtocol.swift`（仅加 Notification.Name）
  - `Tests/AlgorithmTests/LiveWorkoutControllerVLTests.swift`（新增）
- 不改算法 / 连接协议 schema / iPhone 端
- watch app 大约减 ~600 LOC 死代码
