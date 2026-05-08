## Context

Watch 屏幕极小（45mm 表盘约 396×484pt），训练中手腕汗多、单手操作。设计稿用 HTML/CSS 表达，需要原样转 SwiftUI。

## Goals / Non-Goals

**Goals:**
- 14 个屏幕全部出现在 NavigationStack
- LiveWorkout 屏幕「巨大数字 + 颜色状态」可一眼看清
- 震动反馈的 4 种模式按 PRD §M5 触发

**Non-Goals:**
- 不实现真正的 Onboarding（在 iPhone 端做）
- 不接 SwiftData 持久化（Proposal 4 做）
- 不接 HealthKit Readiness 数据（Proposal 7 做，本 proposal 用 mock 数据展示界面）

## Decisions

### D1: NavigationStack vs TabView

用 `NavigationStack` + `path` driving，因为：
- Watch 主流程是一条线（开始→选动作→输重量→训练→休息→总结）
- TabView 在 Watch 不直观

### D2: 震动 API

`WKInterfaceDevice.current().play(_:)`：
- `.success` (双击) → excellent
- `.click` (单震) → met
- `.directionUp` → borderline
- `.failure` (三震急促) → failed
- `.start` → 倒计时结束 / 警戒

### D3: 纯黑背景 + 系统色

所有 Watch 屏幕背景用 `Color.black`（OLED 省电）。文字用 `Color.white` / `Color.secondary`。强调色用 `Tokens.Color.accent`。

### D4: 占位数据

Proposal 3 不接真实数据流，所有屏幕通过初始化器接收 mock 值，方便单独预览和后续 Proposal 4 注入真数据。

## Risks / Trade-offs

- 设计稿的 HTML 自由度大（任意像素布局），SwiftUI 要在 GeometryReader/HStack/VStack 框架内表达，可能有 1-2pt 偏差 — 接受
