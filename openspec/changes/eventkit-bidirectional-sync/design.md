## Context

EventKit 的 `EKEventStoreChanged` 通知不告诉哪些事件改了，只告诉"有东西变了"。所以反向同步策略只能是 "全量轮询小窗口"。窗口选 ±30 天，覆盖最近周计划 + 一些历史 + 一些未来日程，对性能也友好。

## Decisions

### D1：用 fetchRequest 比对 eventKitIdentifier，不维护本地变化日志

每次通知触发时，从训练日历 fetch ±30 天所有事件 → 用 identifier 当 key 比对本地 DayPlan：
- identifier 命中且 start 时间不一致 → 更新 DayPlan.date/scheduledTimeMinutes
- identifier 命中且时间一致 → no-op
- 本地 DayPlan 有 identifier 但 fetch 结果里没有 → 用户在日历里删了 → 删除 DayPlan
- fetch 结果里出现陌生 identifier → 用户手动新建了一条训练事件，**忽略**（不创建 DayPlan，因为我们没有 templateId 信息）

### D2：completed 的 DayPlan 不被反向修改

如果 DayPlan.completed = true（V1 还没主动 mark，V2 会），即使日历事件改了也不动。理由：保护历史完整。

### D3：requestFullAccess 单独于 requestWriteAccess

PR #2 已请求 write-only access。read 访问需要单独的 full access prompt。这意味着用户能选择"只写不读"或"读写都开"。Spec 里两条权限说明字符串都已加。

### D4：ModelContext per reconcile，不长持

每次 reconcile 用临时 `ModelContext(container)`，写入后 `try? context.save()`。避免 shared MainActor context 跨任务竞争。

## Risks / Trade-offs

- **Risk**: ±30 天窗口外的旧事件被改了不会同步。**Trade-off**：可接受，旧事件用户基本不动
- **Risk**: 用户在日历手动新建训练事件 → 我们忽略。**Trade-off**：避免在没有 templateId 的情况下创建 DayPlan；用户应该回 VBTrainer 用 PlanView 安排
- **Risk**: EKEventStoreChanged 触发频繁（用户编辑无关日历也会触发）。**Mitigation**：reconcile 用 fetch + diff，没变化时 no-op；ModelContext.save() 没改动时是 cheap
- **Trade-off**: 不做防抖。用户连续编辑会触发多次 reconcile，但每次都很快

## Open Questions

- 是否扩展到通知中心 UI 通知 "已从日历同步 N 个变更" — V1.5 polish 时做
