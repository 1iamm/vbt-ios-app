## Context

iPhone PlanView 编辑器已经支持每组独立调，模型 `TemplateSetSpec` 持久化每组的 kind / weightKg / reps / restSeconds。但 `TemplateSnapshot` 跨平台协议（Codable，跨 WatchConnectivity 序列化）没有这个维度，所以 Watch 端拿不到具体每组参数。

## Decisions

### D1：snapshot 用值类型 array，不用 dictionary

`setSpecs: [TemplateSetSpecSnapshot]` 是按 index 排序的数组。理由：
- 数组的 Codable 默认实现简单可靠（dict 在 JSON 里以 string-keyed object 序列化，需要稳定 key）
- 顺序天然映射到训练顺序（W → 1 → 2 → ...）
- 与 SwiftData 端 `orderedSetSpecs` 同构

### D2：snapshot 字段默认空，旧客户端零兼容成本

`setSpecs` 字段在 JSON 中默认 `[]`。旧 Watch 安装收到 snapshot 解码时仍能成功（字段被忽略），落入 fallback 路径继续按 targetSets/Reps/Weight 跑。新 Watch 安装收到旧 iPhone 发的 snapshot 解码时同样落入 fallback。无需 schema 版本字段。

### D3：Watch controller plan-aware 的最小 API 表面

只在 controller 加 4 件事：
1. `plannedSpecs` / `plannedSetCursor`：已加载的 plan 数据 + 当前游标
2. `preparePlanned(item:)`：从 snapshot 把 plan 加载进 controller（在 push 路由前调）
3. `nextPlannedParams`：让 RestView 能 inspect 下组参数
4. `endSet()` 自增 cursor，`startNextSet()` 默认从 plan 拉参数

不引入新的 route 类型；既有的 `.liveWorkout(exerciseId, weightKg)` 路由参数沿用。route 的 weightKg 为第一组的 weight（保持 view 接口不变）。

### D4：preparePlanned 的字段持久化跨 reset

`resetForNewWorkout()` 清掉 published 字段以备新训练，但 `plannedSpecs / plannedSetCursor / lastResolvedRest` 跨 reset 保留 — 因为 preparePlanned 在 push 路由前调（早于 LiveWorkoutView.task → controller.start → resetForNewWorkout）。`complete()` / `clearPlanned()` 在训练结束时清理。

### D5：start() 在 plan 模式下不覆盖 preparePlanned 设的字段

LiveWorkoutView.task 调 `controller.start(exerciseId:, weightKg:)` 时不知道 plannedSpecs 的存在。原 start 直接用 args 写入 currentExerciseId/currentTargetRange/currentVLCeiling — 这会覆盖 preparePlanned 写入的 vlCeiling 和 targetRange。Fix：start() 检查 `plannedSpecs.isEmpty`，非空时保留 preparePlanned 的字段。

## Risks / Trade-offs

- **Risk**: 用户在 Plan 编辑器没配 setSpecs（直接保存默认 3×5），Watch 端会走 fallback 旧路径 — 与 PR #2 行为一致，符合预期
- **Risk**: 多动作 plan 在 Watch 上还是手动从 PlanProgressView 选下个动作。**Trade-off**：自动跨动作切换（A1完成 → 自动跳 A2）需要 controller 持有完整 plan + item-cursor，本 change 不做
- **Risk**: 协议解码错误时整个 .template message 解码失败 → Watch 完全收不到。**Mitigation**：setSpecs 默认 `[]`，新增字段不破坏旧 codable schema
- **Trade-off**: RestView 倒计时仍是从 route arg 来的（90 秒），实际 plan 配置的 restSeconds 不影响 RestView 显示。改 RestView 用 `controller.lastResolvedRest` 是更佳但本次不做

## Migration Plan

无破坏性变更：旧 Watch / 旧 iPhone 都通过 fallback 继续工作。新 Watch + 新 iPhone 自动启用每组独立参数。

## Open Questions

- 跨 item 自动切换（A1 done → A2）需要 plan 顶层游标，下个 change 做
- RestView 用 plan 实际 rest 而非固定 90 秒
