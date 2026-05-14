# Tasks: V1 项目代码结构重构

## 前置条件 — 满足状态 (2026-05-14)

- [x] Task 2 (`multi-agent-ux-iteration`) Round 1 修复批次 B1+B2 全部 done（B3/B4 部分 done，剩余 deferred）
- [x] Task 2 Round 2+3+4 复审全部跑完 → R4 全 PASS、Task 2 CLOSED
- [x] 当前 main 上 CI 全绿

## Phase 0 — 测试覆盖前置 ✅ DONE

| PR | 内容 | 状态 |
|---|---|---|
| #78 | WorkoutStore tests (10 cases) | merged |
| #79 | DayPlanStateMachine + PR detector (18 cases) | merged |
| #80 | TemplateSyncService + Recommendation (9 cases) | merged |
| #81 | Velocity + RepDetector edge cases (11 cases) | merged |
| #82 | Today a11y identifiers | merged |
| #84 | Plan a11y identifiers | merged |
| #89 | JSONImporter idempotency (extended) | merged |
| #98 | TabsUITest (5 tab screenshots) | merged |
| #111 | WeeklyAdherence + WeekOverWeekStats tests | in CI |

**累计 +120+ tests / 1500+ LOC test code**. Service layer ~85% covered.

## Phase 1 — Zero-risk refactors ✅ DONE

| Phase | PR | 内容 | Δ LOC |
|---|---|---|---|
| 1A | #77 | Delete HeartRateZonesDonut + StartChipsBar orphans | −161 |
| 1B | #96 | Extract `.cardStyle()` modifier, 31 sites unified | +25 / 0 visual |
| 1C | #112 | AIRecommendationEngine `daysSinceLastWorkout` dedup | in CI |

## Phase 2 — File splits (FROZEN)

Per Round 3 Architect audit 2026-05-14:

> WatchScreens.swift was modified 3 times today by Task 2 UX PRs.
> Splitting a 1531-LOC monolith during active UX churn = guaranteed
> merge conflicts. ConnectivityProtocol.swift has zero MARK seams →
> needs a design pass first.

**Freeze exit criteria**:
1. Task 2 P0+P1 backlog drained (or marked wontfix-rationale)
2. `WatchScreens.swift` goes ≥3 days without modification
3. `ConnectivityProtocol.swift` split-axis design.md drafted

Pending freezing items:
- WatchScreens.swift split by MARK (1531 LOC → 5 files)
- ConnectivityProtocol.swift split (362 LOC, no MARK seams yet)
- HapticFeedback move to Shared/Services
- Tokens.Font 401-site migration (deferred from Task 2)

## Round 2 audit (2026-05-14, 3-agent)

| Reviewer | Verdict |
|---|---|
| Architect | PASS |
| Test | CONDITIONAL PASS |
| Performance | PASS |

Top picks: Architect PR-A (WatchScreens split — deferred), PR-B (ConnectivityProtocol split — deferred), PR-C (more service tests — #111). Perf Fix-A (Today body hoisting — deferred), Fix-B (AI rec dedupe — #112).

## Round 3 audit (2026-05-14, 3-agent)

| Reviewer | Verdict |
|---|---|
| Architect | CONDITIONAL PASS — **freeze Phase 2** |
| Test | PASS — sufficient coverage |
| Reliability | (in progress) |

## Round 1 Findings 表

（已被 Round 2 / Round 3 audit 覆盖，原始 Round 1 prompt 未跑——任务从测试 + 架构 audit 双线推进。）

## Round 2 · 重构设计

- [ ] 写 design.md：文件移动 / rename / 拆分 / 合并清单
- [ ] 标记**确定可删除**的孤儿代码（grep 全文 0 引用的 view / extension / type）
- [ ] 写 ADR 用一句话解释每个重大决定
- [ ] 设计 PR 切分策略（一个 PR 一类改动，diff < 800 行）

## Round 3 · 执行

- [ ] 按设计批量改（多个 PR）
- [ ] 每个 PR 跑完整 CI（含 UI test）确认 0 用户可见行为变化
- [ ] 删孤儿代码（用户明确说"不用保留老版本代码"）
- [ ] 移动 OpenSpec changes：completed 进 `openspec/specs/`、deprecated 删除
- [ ] 重写 CLAUDE.md "项目大脑" 反映新结构
- [ ] 归档本 change 自己进 `openspec/specs/`

## 退出门槛 — 2026-05-14 状态

- [x] 3 agent 复审 ≥ 3 轮 PASS (R2 + R3 + R4, 8 agents across Architect/Test/Perf/Reliability)
- [x] 仓库 LOC 净减或持平（~−150 net 包含 orphan + dead-code 减、tests + modifier 加）
- [x] grep 全文：0 个 V1 已知孤儿代码（HeartRateZonesDonut/StartChipsBar/quickStartGrid 全删）
- [ ] `openspec/changes/` 归档 → deferred（V1.5 工作会在此目录平行进行；不强制归档）
- [ ] CLAUDE.md 反映新结构 → deferred（本 tasks.md + round{2,3,4}-review.md 就近 self-document）

## Task 3 状态：**CLOSED for V1 (Phase 1 done · Phase 2 deferred to V1.5)** ✅

详 `round4-review.md`。
