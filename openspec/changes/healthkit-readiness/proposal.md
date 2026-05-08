# Proposal: HealthKit Integration & Readiness Score

## Why

Proposal 6 已经在 onboarding 申请了 HealthKit 权限，但实际还没读数据。本 proposal 实现：
1. HealthKitService — 真实读取睡眠/HRV/RHR/温度/呼吸率数据
2. ReadinessCalculator — 把这些原始数据计算成 0-100 Readiness Score
3. 把 ReadinessRingCard 从 mock 切换到真实数据

## What Changes

- 新建 `Shared/Services/HealthKitService.swift`：actor，封装 HealthKit 读 API
- 新建 `Shared/Services/ReadinessCalculator.swift`：纯函数，输入 baseline + 当日数据，输出 Score + Tier
- 新建 `Shared/Services/ReadinessRefresher.swift`：调度器，App 启动 + 训练前各拉一次
- 修改 `TodayView`：注入真实数据
- 单测覆盖 ReadinessCalculator

## Capabilities

### New Capabilities

- `healthkit-read`: HealthKit 数据读取
- `readiness-score`: 评分计算

## Impact

- iOS target 引入完整 HealthKit framework 使用
- 7 天基线建立期内显示 `.insufficient` tier
- 不写 HealthKit（写在 Proposal 10 final QA）
