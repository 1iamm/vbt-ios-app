# Proposal: Comprehensive Timeline Redesign

## Why

`ComprehensiveChartView` 是 V1 的简单 overlay（HR 折线 + 速度 PointMark + RuleMark 组分隔）。Claude Design V4 chat 里用户分 4 轮迭代了具体诉求：

1. 上轴按"组"划分，每动作不同色，组与组之间不连续
2. 下轴双层：绝对时间 19:24 + 相对时间 +0m
3. 心率 / 速度 / VL% 三种数据可点击图例切换显隐
4. VL 25% 警戒线只在每组色带正下方画一截虚线，不贯穿全图

PR #2 把这些改动留作 Out of Scope，本 change 落地。

## What Changes

- **重写** `VBTrainer/Views/History/ComprehensiveChartView.swift`：
  - 顶部组带（chartOverlay 渲染）：每组一个独立 6pt 色块，组与组之间留白；同动作（exerciseId）同色；首次出现的动作上方加 small-caps 名字标签
  - 心率 LineMark（实线，左 BPM 轴 40-220）
  - 速度 PointMark 散点（右 m/s 0-1.5，映射到同 BPM 域以便共轴）
  - VL% 段状虚线（每组色带下方对应位置画一截，不贯穿）
  - 双层 X 轴（GeometryReader + 5 等分采样）：上行绝对 HH:mm 主文字色 / 下行相对 +Nm 三级灰
  - 图例可点击：3 个数据系列各一个 Toggle（HR/Velocity/VL%），点击 toggle 隐藏对应 marks + 对应右侧 axis label 灰化

## Capabilities

### New Capabilities
（无新 capability — 替换既有 view 实现）

### Modified Capabilities
- `iphone-history-calendar`（既有 spec 中 "查看综合时间轴" 入口的视觉契约更新）

## Impact

- 仅 iOS target 一个 view 重写；调用方（WorkoutDetailView 的 `ComprehensiveTimelineLandscape` wrapper）不变
- 数据接口不变（仍读 Workout.heartRateSamplesData + sets.reps）
- 无第三方依赖，仍用 SwiftUI Charts
