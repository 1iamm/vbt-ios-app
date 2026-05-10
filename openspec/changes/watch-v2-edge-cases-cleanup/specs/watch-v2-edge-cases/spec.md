# watch-v2-edge-cases

## Purpose

V2 设计稿没画但工程层必须做的边缘场景：VL 强制停组触发、单边动作 chip、V1 死代码
清理。

## Requirements

### VL 强制停组触发

- `LiveWorkoutController.apply(_:)` 在收到 `.vlCeilingExceeded(vl, threshold)` 时
  SHALL post `Notification.Name.vbtVLCeilingExceeded`，userInfo 含 `vl: Double`、
  `threshold: Double`
- `Notification.Name.vbtVLCeilingExceeded` SHALL 在 ConnectivityProtocol.swift
  附近定义为 public 常量
- `WatchRootView` SHALL 在收到该通知时 `nav.push(.vlStopWarning(vl, threshold))`
- 通知发布 SHALL 不依赖任何 view 是否在屏（actor 事件流自由触发）

### SetReady side chip

- `SetReadyView` SHALL 在 `controller.currentSide != .both` 时显示一个 11pt 蓝色
  圆角 chip，文案：`.left → "左侧"`、`.right → "右侧"`
- chip 位置 SHALL 在动作名右侧或下方，不抢主视觉
- `controller.currentSide == .both` 时 SHALL 不渲染 chip

### V1 死代码清理

- `WatchScreens.swift` SHALL 删除以下 view struct：
  - `WatchHomeView`
  - `WatchExercisePickerView`
  - `WatchWeightInputView`
  - `WatchCMJCountdownView`
  - `WatchCMJGoView`
  - `WatchCMJResultView`
  - `WatchPlanProgressView`
  - `WatchPlanNextView`
- `WatchReadinessView` SHALL 保留，但删除其内的「CMJ 测试」按钮入口
- `WatchRoute` enum SHALL 删除以下 case：
  - `exercisePicker`
  - `weightInput`
  - `cmjCountdown`
  - `cmjGo`
  - `cmjResult`
  - `planProgress`
  - `planNext`
- `WatchRootView.routeView(_:)` switch SHALL 同步移除上述 case 的分支

### 单元测试

- `Tests/AlgorithmTests/LiveWorkoutControllerVLTests.swift` SHALL：
  - 构造 controller，调 `apply(.vlCeilingExceeded(vl: 0.4, threshold: 0.3))`
  - 通过 `NotificationCenter.default.publisher(for: .vbtVLCeilingExceeded).first()` 等待通知
  - 断言 userInfo 字段值正确

## Behaviour

#### Scenario: VL 突破阈值
- **WHEN** `ActiveWorkoutSession` 检测到 VL > ceiling 并发出 `.vlCeilingExceeded(vl, th)` 事件
- **THEN** `LiveWorkoutController.apply` post `.vbtVLCeilingExceeded` 通知
- **AND** `WatchRootView` push `.vlStopWarning(vl, th)` 路由
- **AND** `WatchVLStopWarningView` 显示警告内容

#### Scenario: 单边动作训练
- **WHEN** `controller.currentSide = .left`
- **THEN** SetReady 屏在动作名旁显示「左侧」蓝色 chip

#### Scenario: 删除 V1 路由后无残留引用
- **WHEN** `./scripts/verify.sh` 跑完
- **THEN** cross-file symbol resolution 不报任何对已删 view / case 的引用
