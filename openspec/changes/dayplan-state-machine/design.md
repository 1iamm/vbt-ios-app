## Context

PR #2 把"今天"banner 闭锁在 "DayPlan 存在 ⇒ 显示开始按钮" 的二态。所有下游决策（已练完 / 跳过 / 错过）只能在每个调用点重新推断，导致行为不一致。

两位 PM 一致：先建立单一事实来源（status 字段 + 状态机服务），再让 banner / dots / 反向同步 / AI / stats 改读它。

## Decisions

### D1：5 态够用，不需要 inProgress 的精确触发

5 态：`scheduled`（默认）/ `inProgress`（Watch 训练中）/ `completed`（落库）/ `skipped`（用户主动）/ `missed`（午夜后未做）。

`inProgress` 的精确同步要求 Watch 训练开始时反向 push 一条信号给 iPhone，本 change 不做（架构整改，留 Round 2/3）。当前实现：banner 在 scheduled 状态用 "从 Watch 开始" 文案，用户开始训练后 banner 还是 scheduled——这个 5%-发生的边角不影响主要用户路径。完成后由 markCompleted 直接跳过 inProgress 一档。

### D2：legacy `completed: Bool` 保留并同步

直接删字段会破坏现有持久化（用户训练完早期版本可能存了 completed=true）。保留字段，setter 同步：`status = .completed` ⇒ `completed = true`。下游可以渐进迁移到 status，不阻塞本 change。

### D3：reconcileMissed 在 app launch 跑一次，不引入 BGTask

PM 系统 agent 提到 BGTask 触发午夜判定。BGTask 注册要在 Info.plist 加 BGTaskSchedulerPermittedIdentifiers + 处理 launch handler，工程量较大且稳定性受 system 约束。简化版：app 每次 cold launch 跑一次 reconcileMissed。代价是用户必须打开 app 才会看到"missed" — 可接受，因为 missed 状态本来就是给 app 内部用的，不发系统通知。

### D4：reverse syncer 用 markSkipped 替代 delete

之前 syncer 在日历事件消失时 `context.delete(plan)`。改为 `plan.status = .skipped`：
- 历史可看见用户取消轨迹（V1.5 心理学）
- 防止 reconcileMissed 把"该 missed 的 plan"误判（被 skipped 的 plan 不该出现在 missed 列表）

### D5：ScheduledTrainingCard 升级为状态驱动 view

之前 hard-code "已安排" 文案 + 主按钮 "从 Watch 开始"。重构为：
- 加 `status: DayPlanStatus` 必传
- 加 `summary: ScheduledSummary?`（completed 状态下展示 4 项数据）
- 内部 `Theme` 结构体根据 status 计算 bg/stroke/badge/primary/secondary/footer
- 调用方（TodayView）只关心 onPrimary/onSecondary 的语义路由，不关心 UI 切换

### D6：banner section title 也跟状态走

之前 SectionHeader title="已安排今日"。改为 `bannerSectionTitle(for:)` 计算属性返回相应文案。这个细节让用户在 banner 之上一层就感知到状态切换，无需读细节字。

## Risks / Trade-offs

- **Risk**: legacy `completed: Bool` 与 `status` 双写，未来谁忘了 status 直接改 completed 会脱节。**Mitigation**：将 `completed` 改为 `private(set)`、注释禁止外部直写——本次先打文档注释，下次 change 再加访问控制
- **Risk**: 用户连续两天打开 app，第一天的"missed"会一直显示。**Trade-off**：missed 在 Today 当前不渲染（只有 today 的 plan 进 banner），所以不会误导。History 列表会展示 — 符合预期
- **Trade-off**: 不发系统通知"昨日漏练"。如果用户根本不打开 app 就不会看到这个状态。下次 change 加 UNUserNotificationCenter

## Migration Plan

- DayPlan 加新字段：SwiftData lightweight migration 自动处理（默认值已设）
- 既有 DayPlan 行：statusRaw 默认 `"scheduled"`、statusUpdatedAt 默认创建时间
- backfillLegacyCompleted：扫一次 `completed == true && statusRaw == "scheduled"` 的行，标 `.completed`
- 第二次 cold launch 起 reconcileMissed 把过期 scheduled 转 missed
