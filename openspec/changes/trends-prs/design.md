## Context

长期趋势与 PR 是 VBT 工具的差异化（vs Strong/Hevy），LVP + e1RM 是基于论文的科学量化。

## Goals / Non-Goals

**Goals:**
- 单动作选择 → 看到该动作过去 N 天的进步
- LVP 在数据足够时显示（≥ 5 组不同重量），不足时显示进度提示
- PR 在每次训练完成后自动检测

**Non-Goals:**
- 不做跨动作对比图
- 不做导出图为图片功能
- 不做 PR 推送通知（V1 仅记录）

## Decisions

### D1: LVP 简单线性回归

`v = a × load + b`，最小二乘法。e1RM = (V1RM - b) / a。
若 a >= 0（异常曲线），返回 nil。

### D2: PR 触发时机

`iPhoneConnectivityService` 收到 workout 时调 `PersonalRecordDetector.checkAndRecord`。
检测的 PR 类型：maxWeight / maxVolume / maxSingleRepVelocity / e1RM（如有 LVP）。

### D3: trend 图表

用 Swift Charts 单图，时间为 X，metric 为 Y。提供时间范围切换（30/90/all）。

## Risks

- 5 组阈值可能让初期用户长期看不到 LVP — 加 progressive 提示卡（"再 N 组"）
