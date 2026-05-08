## Context

Apple HealthKit 提供 sleep / HRV / RHR / wrist temperature / respiratory rate / VO2Max 等。需要异步拉取并计算 Readiness。

## Goals / Non-Goals

**Goals:**
- 拉取最近 7 天数据建立 baseline
- 计算 Readiness Score (0-100)
- 数据不足时显示 `.insufficient` 状态而非 0

**Non-Goals:**
- 不实现真机 HealthKit 集成的全面校准（V1 末看真实数据再调）
- 不写 Workout 到 HealthKit（Proposal 10）
- AI 推断 → V2

## Decisions

### D1: Readiness 公式

```
score = w_hrv × hrvDeviationScore + w_rhr × rhrDeviationScore +
        w_sleep × sleepScore + w_temp × tempDeviationScore
```

权重（论文推导）:
- HRV 50%
- 睡眠 25%
- RHR 20%
- 手腕温度 5%

每个子分数 0-100，加权求和得 Score。

### D2: 基线策略

7 天滚动均值 + std。HRV / RHR 偏离基线 ±1 std 内 = 100 分；±1.5 std = 70；±2 std = 30；超出 = 0。

### D3: 异步加载

`ReadinessRefresher.refresh()` 是 async；TodayView 用 `.task` 触发；结果写 SwiftData，UI 通过 @Query 自动刷新。

## Risks

- HealthKit 在没数据时返回空数组，必须用 `.insufficient` 优雅处理
- iOS simulator 的 HealthKit 没数据；真机才能看到效果
