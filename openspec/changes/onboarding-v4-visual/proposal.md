# Proposal: Onboarding V4 Visual Refresh

## Why

PR #2 落定了 5 步主动线但保留了 V1 的 Onboarding（5 步 form-based）。设计稿明确 4 屏：欢迎 / 价值主张 / HealthKit 授权 / 个人画像。本 change 把 Onboarding 重构成 4 步并对齐 V4 视觉。

## What Changes

- **重写** `VBTrainer/Views/Onboarding/OnboardingView.swift`：
  - 4 步替换 5 步（合并基础+背景到一屏）
  - 顶部 dots 进度（当前步用宽 capsule 高亮 accent 色）
  - 大字 hero（44pt 标题 + small-caps eyebrow）
  - 价值主张步：3 个 row 格式（图标 + 标题 + 副文案）
  - 个人画像步：折叠 group 风格（基础 / 训练背景）+ Picker.segmented
  - 底部双按钮（圆形返回 + accent CTA capsule + 阴影）
  - 步骤切换动画：`.move(edge:).combined(with: .opacity)`
  - accent 色根据已选 trainingGoal 动态变色（最后一步选目标后视觉同步切换）

## Capabilities

### Modified Capabilities
- `iphone-onboarding`（既有）— 视觉重构

## Impact

- 仅 iOS target 一个 view 重写
- 流程不变：仍创建 UserProfile + 触发 onCompleted
- HealthKitPermissionView 复用不动
