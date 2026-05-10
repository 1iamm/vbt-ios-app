# Tasks

## VL 触发链路

- [ ] `Shared/Services/ConnectivityProtocol.swift`：
  - [ ] 加 `public static let vbtVLCeilingExceeded = Notification.Name("vbt.vlCeilingExceeded")`
- [ ] `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift::apply(_:)`：
  - [ ] `case .vlCeilingExceeded(let vl, let th)` post 通知（不再 break）
- [ ] `VBTrainerWatch Watch App/Views/WatchRootView.swift`：
  - [ ] `.onReceive` `.vbtVLCeilingExceeded` → `nav.push(.vlStopWarning(...))`

## SetReady side chip

- [ ] `WatchScreens.swift::SetReadyView` 加 chip 渲染（仅 `currentSide != .both`）

## V1 死代码清理

- [ ] `WatchScreens.swift` 删除 8 个 view struct（含 Readiness 内的 CMJ 按钮 + 整个 ReadinessView 内 CMJ 入口删除）
- [ ] `WatchNavigation.swift` 删 7 个 V1 路由 case
- [ ] `WatchRootView.swift` switch 同步删除分支
- [ ] 全文 grep 确认无残留 push 调用

## 单元测试

- [ ] `Tests/AlgorithmTests/LiveWorkoutControllerVLTests.swift`：测 `.vlCeilingExceeded` 触发通知

## 验证

- [ ] `./scripts/verify.sh` 通过
- [ ] watch + iPhone target build 通过
- [ ] xcodebuild test 不 regression
