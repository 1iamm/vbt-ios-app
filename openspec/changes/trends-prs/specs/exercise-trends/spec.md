## ADDED Requirements

### Requirement: 单动作长期趋势

`ExerciseTrendView(exerciseId:)` SHALL display:
- 时间范围切换 (30/90/all days)
- 最大重量进步曲线 (Chart)
- e1RM 进步曲线 (Chart) — 仅在该动作有 LVP 计算结果时显示
- 同负重平均速度变化 (Chart)
- 训练量周聚合 (Chart)

数据为空时显示提示，不崩溃。
