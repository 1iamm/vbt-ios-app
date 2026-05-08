## Context

iPhone 端的差异化在于「数据复盘」。综合图表必须信息密度高、视觉清爽。

## Goals / Non-Goals

**Goals:**
- 4 Tab Bar 主结构，符合 iOS HIG
- Today 页极简（仿 Apple 健身 App 摘要风格）
- History 详情页综合图表能在一张图同时展示心率、速度、动作切换、休息区间
- 所有图表用 Swift Charts，零第三方

**Non-Goals:**
- 长期趋势 / LVP / PR 列表 → Proposal 8
- Plans 编辑器 / 个人画像 → Proposal 6
- 真 Readiness 计算 → Proposal 7（先 mock 一个 score 给视觉用）

## Decisions

### D1: Swift Charts 多 Y 轴

`Chart` 内 `chartYAxis` × 2 + `chartXScale`。心率与速度共用时间轴。
设计稿要求一张图叠加，用 Apple 自家的 ChartContent 组合 LineMark + PointMark + RectangleMark + RuleMark。

### D2: Heatmap 自绘

Swift Charts 没有 GitHub-style heatmap，自己用 LazyVGrid + 颜色阶映射。
30 天最大训练量决定饱和度上限。

### D3: 数据驱动 + 占位

`TodayView` 用 `@Query` 拉数据：最近 1 个 workout、最近 30 天 readiness、最近 30 天 workouts。
没数据时显示 EmptyState 文案（"还没有训练记录，去 Watch 上开始第一次训练吧"）。

### D4: 详情 NavigationStack

`HistoryView` 是个 NavigationStack，点 row 推 `WorkoutDetailView(id:)`。

## Risks / Trade-offs

- 综合图表在小屏 iPhone (mini) 可能拥挤 — V1 接受，未来加横屏全屏
