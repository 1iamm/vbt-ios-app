## Context

Round 1 让 DayPlan.status 成为单一事实。本轮把"状态变化"变成"事件流"，让 UI / Stats 都订阅它，而不是各自 poll @Query。

## Decisions

### D1：单一 AsyncStream<DayPlanEvent>，不分通道

`DayPlanEventBus` 只暴露一个 stream。Subscribers 自己 switch 关心的 case。理由：
- 事件少（4 种），一个 stream 不会拥堵
- 跨平台 Sendable AsyncStream 是当前 Swift 标准方式
- 比 NotificationCenter + name-based 派发更类型安全

### D2：buffer policy = bufferingNewest(32)

Subscribers 可能晚加入（TodayView 出现前 reverseSyncer 已经发了几条）。bufferingNewest(32) 意味着断订后最多丢 32 条事件之外的，足够覆盖 cold launch 场景。

### D3：Celebration 优先级：PR > 周满训 > streak > generic

ROI 排序——PR 是最稀有最高情绪事件；周满训次之；streak 第三；最后才是 generic。同一次 completion 只触发一种庆祝（避免连环弹）。

### D4：streak 里程碑选 [3, 7, 14, 30, 60, 100]

跳跃式选择，避免"连续 11 天" 这种平庸数字也弹卡。**3** 是习惯成形临界（PNAS 2009），**7** 一周节奏，**14** 双周，**30** 一个月，**60** / **100** 留着 V2 让重度用户感受到长期价值。

### D5：6s 自动消失 + 可手动滑走

用户测过 8s 太长（庆祝完仍占视觉），3s 太短（没看清就走）。6s 是健身/记账 app 的中位数。横向滑走立即关，纵向上滑也算关。

### D6：WeeklyAdherenceCalculator.currentStreak 算法

向后扫描 120 天 DayPlan，按 `cal.startOfDay` index。从 today 倒推：
- completed → streak +1，往前一天
- missed / skipped → break
- 没有 plan（rest day）→ neutral，不增不减，往前一天（除非 streak == 0 且不是 today 起点 → break）

避免"连续 5 天里有 1 天休息"被误判为中断。

### D7：narrativeLine 文案规则

按 weekly 状态 + week-over-week delta 拼短句。规则：
- isFullyCompleted → "本周满训"
- 否则报 "已完成 N/M"，有 missed 加 "漏 X"
- 训练量 delta ≥ 5% 加 "高于/低于上周 X%"
- 速度 delta ≥ 3% 加 "更快/略慢"
- 否则 fallback "本周训练数据建立中"

短句优先级：节奏 > 量 > 速度。降低读认知负担。

## Risks / Trade-offs

- **Risk**: 用户连续 100 天里某天 missed → streak 被打断到 0，再过 99 天才能再触发 100 milestone。**Trade-off**: 接受。streak 本来就是"连续"的语义
- **Risk**: bufferingNewest(32) 在事件极端密集（比如批量 reconcileMissed）下会丢事件。**Mitigation**: missed 事件目前是聚合一次 publish 整个 ids 列表，不会刷屏
- **Trade-off**: CelebrationCard 不持久化"已显示" — 用户多次打开 app 会再次看到同一个 milestone。次轮加 "已展示过的 milestone 进 UserDefaults" 即可

## Open Questions

- 是否给 Watch 也加 mini celebration（震动 + 一行文字）？V3 考虑
- Stats 叙事接 LLM？V2 AI 后做
