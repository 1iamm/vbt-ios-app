# Proposal: Watch UI Screens

## Why

Proposal 2 提供了传感器和算法。本 proposal 把它们包装成用户能看见、能操作的界面——按 Claude Design 输出的 watchOS 设计稿（`design/watch/vbt/project/screens.jsx` + `screens-prd.jsx`）实现 Watch 端 14 个屏幕和震动反馈。

## What Changes

- 新建 14 个 SwiftUI Watch 屏幕（Home / Readiness / CMJ流程 / ExercisePicker / WeightInput / LiveWorkout / Rest / Summary / PlanProgress / PlanNext / PRCelebration / VLStopWarning / RPEInput / Settings 入口）
- 新建震动反馈引擎（`HapticFeedback.swift`）—— 4 种 rep 完成震动 + 倒计时结束 + VL 警戒
- 新建 `WatchTheme.swift` —— 提取 Watch 专属颜色（深色 OLED 友好），与 `Tokens` 协同
- 新建 `WatchNavigation.swift` —— 集中管理 Watch 端 NavigationPath 流转
- 把 `WatchRootView` 从占位改成真正的 Home

## Capabilities

### New Capabilities

- `watch-screens`: 14 个屏幕的 SwiftUI 实现
- `watch-haptics`: 4 阶震动反馈引擎
- `watch-navigation`: 屏幕跳转流

### Modified Capabilities

（无）

## Impact

- 仅 watchOS target
- 引入 `WatchKit` 的 `WKInterfaceDevice.current().play(_:)` 用于震动
- 设计稿数值（字号/间距/颜色）必须 1:1 对齐
