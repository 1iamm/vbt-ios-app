# Proposal: AI Recommendation Routes (Click-Through)

## Why

PR #2 加了 AI 推荐紫色卡（rule-based stub）但卡片不可点击。本 change 接通点击行为：
- **deload** → 用最近 Template 为底，自动生成 -15% / 减 1 rep 的新模板，跳 PlanView
- **prRetest** → 用最强动作 + 历史最大重量生成 5 组金字塔模板（50/70/85/95/100% × 1RM with reps 5/4/3/2/1），跳 PlanView
- **cmjTest** → 弹 alert 提示 "在 Apple Watch 上启动 CMJ"（V1 简化）

不引入真 AI 模型 — 仅 rule-based + builder。

## What Changes

- **新增** `Shared/Services/RecommendationTemplateBuilder.swift`：
  - `buildPRRetest(exerciseId:, lastTopWeight:, in:)` 生成 2 热身 + 5 工作（金字塔）模板
  - `buildDeload(baseTemplate:, in:)` 克隆 baseTemplate 但 weights × 0.85 / reps -1
- **改** `Shared/Services/AIRecommendationEngine.swift`：
  - `AIRecommendation` 加 `exerciseIdHint: String?` + `weightHint: Double?`
  - deload rule 设 `templateIdHint = latestTemplate.id`
  - prRetest rule 设 `exerciseIdHint + weightHint`（lastTopWeight 取 `Workout.sets.weightKg.max()`）
- **改** `VBTrainer/Views/Today/TodayView.swift`：
  - AI 卡 wrap 在 Button 里 → `applyRecommendation(rec)`
  - applyRecommendation 分类型路由：deload/prRetest 调 builder + 跳 PlanView；cmjTest alert
  - 失败 fallback：找不到 base template / 没有 lastTopWeight 时降级到 createNewTemplate()

## Capabilities

### Modified Capabilities
- `iphone-today-flow`（PR #2 capability）— AI 卡片成为可点击入口

## Impact

- 仅 iOS target
- 新增 Template 持久化（PR 重测 / 减载新模板会出现在 "我的模板" 列表，用户可后续删除）
- 不改协议、不改 Watch 端
