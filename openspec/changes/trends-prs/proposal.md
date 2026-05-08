# Proposal: Long-term Trends + LVP + PR Tracking

## Why

Proposals 5/6 给了单次复盘和模板。本 proposal 实现长期视角：
- 单动作进步曲线（最大重量 / e1RM / 同负重平均速度 / 训练量周聚合）
- 力速曲线（LVP）+ e1RM 估算（5 组不同重量数据后解锁）
- PR 自动检测 + PR 历史

## What Changes

- 新建 `Shared/Services/PersonalRecordDetector.swift`：训练完成时检测 PR
- 新建 `Shared/Services/LVPCalculator.swift`：线性回归 + e1RM
- 新建 `VBTrainer/Views/Trends/ExerciseTrendView.swift`：单动作长期趋势
- 新建 `VBTrainer/Views/Trends/LVPChartView.swift`：力速曲线
- 新建 `VBTrainer/Views/Trends/PRListView.swift`：PR 历史
- History tab 加跳转入口：从 WorkoutDetailView 顶部 toolbar 进入对应动作 trend

## Capabilities

- `pr-detection`: PR 自动检测
- `lvp-e1rm`: 力速曲线 + e1RM
- `exercise-trends`: 单动作长期趋势
- `pr-history-display`: PR 列表

## Impact

- 仅 iOS UI；watchOS 不变
- LVP 需要 ≥ 5 组不同重量才显示
- PR 检测在 connectivity service 收到 workout 后触发
