# Proposal: Watch Post-Workout RPE + Notes Capture

## Why

Round 3 PM 共识。Round 1 + 2 把"开始训练 → 计划状态 → 完成庆祝 → 本周叙事"全打通后，**采集端最后一个漏洞**是主观负荷（RPE）和当下感受（笔记）从未在 Watch 上落地。

`Workout.rpe` / `Workout.notes` / `WorkoutSnapshot.rpe` / `WorkoutSnapshot.notes` 字段早就预留了，从未被填入。两位 PM 都判断：这是 V1 唯一能"清债 + 解锁后续"的项 — 其他 10 项要么是新坑（H/L/J），要么是 polish（F/G/N）。

填上这个字段：
- e1RM 调整、Readiness 复盘可以加入 RPE 维度
- Stats narrativeLine 能升级到 "已完成 5/7 · 平均 RPE 7.2"
- V2 AI 复盘的训练样本第一次完整
- 用户训完那一秒在 Watch 上 1 tap 解决，不依赖回 iPhone 补

## What Changes

- **改** `VBTrainerWatch Watch App/Views/WatchScreens.swift` `WatchSummaryView`：
  - 加 RPE 数字（1-10）+ 表冠绑定 + 动态色（success/accent/warning/danger）+ 标签（极轻 / 中 / 重 / 极限 等）
  - 加 3 选 1 感受快捷标签（强 / 正常 / 拉胯）
  - "完成" 按钮改调 `controller.completeWithFeedback(rpe:notes:)`
- **改** `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`：
  - 新增 `completeWithFeedback(rpe:notes:)` 方法 — 在返回 snapshot 前 mutate `snapshot.rpe / snapshot.notes`
  - `complete()` 保留为 backward-compat 转调
- **改** `VBTrainer/Views/History/WorkoutDetailView.swift`：
  - 新增 feedbackCard：未填时显示 "+ 补写感受"，已填时显示 RPE 圆环徽章 + 笔记摘要 + 编辑铅笔
  - 新增 `FeedbackEditorSheet`（RPE Slider + 笔记 TextField + 6 个预设 tag chip）

## Capabilities

### New Capabilities
- `watch-rpe-and-notes`

### Modified Capabilities
- `iphone-history-calendar`（WorkoutDetail 加感受卡 + 编辑器）
- `watch-live-workout`（controller 加 completeWithFeedback）

## Impact

- 仅 UI 层 + controller 接口扩；Workout / WorkoutSnapshot / 协议字段都已预留
- `WorkoutStore.save(snap:in:)` 已经从 snap 拷 rpe/notes 进 Workout — 零改动
- 默认 RPE = 7（多数力量训练真实众数），让用户单击 "完成" 也能落地非空数据
- 笔记 V1 仅文本字段 + 预设 tag chip，不接语音转写（V1.5）
