# Proposal: 多 Agent UX 迭代（可靠性 / 稳定性 / 美观）

## Why

VBTrainer V1 主体功能已实现，但用户视角、交互设计、视觉风格、产品定位多个维度都还有积累的债。Task 1 把"自动验收 + 自动截图 + 自动 PR 评论"工具链做完，本 Task 在此之上做**用 agent 委员会评审 → 出 PR 修复 → 再评审 → 再修复**的循环，直到 3 个 agent 都签字"无 P0/P1 残留"为止。

## What Changes

**Round 1（已完成 2026-05-13）**：
- 4 个 agent 平行 audit：产品经理 / UI 设计师 / 交互设计师 / 用户视角（Zexi 角色）
- 共发现 **61 条 finding**（P0 ~12 条、P1 ~30 条、P2 ~19 条）
- 关键交叉印证 + 单 agent 高严重度 finding 进入待修队列（见 `tasks.md`）

**Round 2 修复批次**（按数据正确性 → 关键 UX → 视觉一致性顺序）：
- B1: 数据正确性 / 完整性硬伤（5s 自动结组 / WorkoutDone ACK / 多动作 Workout）
- B2: 关键交互（结束本组按钮 / 模式记住默认 / SetResult 流程 / PR 庆祝接线）
- B3: 视觉一致性（Color.orange→GoalTheme / Watch 字号 / Tokens.Font 扩档 + 全局替换）
- B4: 功能补全（CMJ Watch View / 长期趋势热力图 / e1RM surface area）

**Round 3 复审**：3 agent 复跑 Round 1 audit checklist，确认每条 finding 状态 = done / wontfix-with-rationale。

**Round 4+**：如果 Round 3 仍有 P0/P1 残留 → 继续修 → 再 Round。

## Capabilities

### Modified Capabilities
- `iphone-onboarding`
- `iphone-today-flow`
- `live-workout-watch-ui`
- `watch-set-state-machine`
- `cross-device-sync-reliability`
- `personal-record-celebration`
- `goal-theme-application`
- `design-token-discipline`
- `multi-exercise-workout-model`（新 capability，schema 改动）

### Added Capabilities
- `cmj-watch-entry`
- `readiness-detail-view`
- `weekly-trend-heatmap`

## Impact

- **大量** SwiftUI view 改动（视觉一致性扫荡，401 处硬编码 font 替换）
- **schema migration**：Workout 模型加 `parentSessionId: UUID?`（risk：现有用户数据需迁移）
- **新 view**：WatchCMJTestView、ReadinessDetailView、TrendHeatmapView
- Watch 端字号 + 触控目标整改影响所有 Watch screens

## Exit Criteria

3 个 agent（重组：可靠性 / 稳定性 / 美观）复审给出：
- 0 条 P0 残留
- 0 条 P1 残留（或所有 P1 都有明确 wontfix rationale + V2 plan）
- 现有 UI test + algorithm test 全过
- 自动验收截图能完整走过：onboarding → today → start workout → live workout → rest → summary → history → PR celebration（如打破）
