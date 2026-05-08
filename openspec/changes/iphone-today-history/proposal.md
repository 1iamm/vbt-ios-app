# Proposal: iPhone Today + History + Comprehensive Chart

## Why

iPhone 端是用户复盘的核心阵地。本 proposal 实现 4-Tab 架构（Today/Train/History/Profile）的根 + Today + History 两个 Tab，重点是「单次训练详情 - 综合时间轴图表」（PRD 标的核心差异化）。Plans 和 Profile Tab 留给 Proposal 6。

## What Changes

- 新建 `RootView` 改成 TabView 4 个 tab
- 新建 Today tab（`TodayView`）：Readiness 圆环 + 上次训练摘要 + 30 天热力图
- 新建 History tab（`HistoryView`）：日期分组列表 + 全量统计
- 新建 `WorkoutDetailView`：单次训练详情（含综合时间轴图表）
- 新建 `ComprehensiveChartView`：基于 Swift Charts 的多 Y 轴叠加图（心率红线 + 速度蓝散点 + 动作切换标签 + 休息区间灰底 + VL 警戒虚线）
- 新建 `WorkoutSummaryCard` / `ReadinessRingCard` / `TrainingHeatmap` 等可复用组件

## Capabilities

### New Capabilities

- `iphone-tabs`: 4 Tab 主结构
- `today-tab`: Today Tab 视图组合
- `history-tab`: History Tab + Workout Detail
- `comprehensive-chart`: 综合时间轴图表组件

## Impact

- 仅 iOS target
- 引入 Swift Charts framework（iOS 16+ 已内置，无依赖）
- Plans Tab 和 Profile Tab 当前显示占位（Proposal 6 替换）
