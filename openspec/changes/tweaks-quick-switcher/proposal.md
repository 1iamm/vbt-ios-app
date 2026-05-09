# Proposal: Tweaks Quick Switcher

## Why

Claude Design 的 Tweaks 面板原型（vbt-tweaks.jsx）允许用户一键切训练目标，全 App 主色与 VL 警戒同步刷新。PR #2 把这个能力埋在 ProfileEditorView（要点 4 层菜单）。本 change 给 TodayView 顶部加一个轻量入口，让切目标变成 "1 tap → bottom sheet → 1 tap" 的两步操作。

## What Changes

- **新增** `VBTrainer/Views/Common/TweaksQuickSwitcher.swift`：
  - `TweaksQuickSwitcher`：一个 sheet，列出 5 个训练目标 + accent 圆点；当前目标 checkmark 高亮
  - 选中目标：写入 UserProfile.trainingGoal + `try? context.save()` + 触感反馈
  - 数据密度 / Readiness 风格 显示为 lock-icon 行（标准 / 圆环 — V1 锁定）
  - `TweaksButton`：圆形 36pt 滑块图标按钮
- **改** `VBTrainer/Views/Today/TodayView.swift`：
  - 加 `@State showingTweaks`
  - 在 ScrollView overlay top-trailing 放 TweaksButton
  - sheet 弹 TweaksQuickSwitcher，绑 `profiles.first`

## Capabilities

### New Capabilities
- `iphone-tweaks-quick-switcher`

## Impact

- 仅 iOS target；零跨平台变更
- 立即生效：UserProfile.trainingGoal 改 → @Query 触发整个 app 重渲染 → GoalTheme 主色全切换
- ProfileEditorView 仍可继续编辑（不动）
