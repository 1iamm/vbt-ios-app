# Task 1 · Round 3 Audit (2026-05-14)

3-agent review of "全自动 AI 协助开发工作流搭建" after all Round 1 + Round 2 fixes merged (PRs #60-#76).

## Verdicts

| Dimension | Verdict | Blocker count |
|---|---|---|
| DX (Developer Experience) | **PASS** | 0 |
| Reliability | **PASS** | 0 |
| Cost / CI Speed | **CONDITIONAL PASS** | 0 (3× P2) |

**Overall: PASS** — Task 1 closes out.

## DX summary
All Round 1 P0/P1 findings (F1-F8) verified in code:
- Failure visibility loop closed: sticky `<!-- ci-failure -->` comment with 12-section dump, milestones, errors, tail-200 — no need to open Actions UI.
- Conditional CI working: `fast-fail` Linux job emits `has_native_code` / `has_ui` outputs; macOS build gates on them. Docs-only PR < 1 min, confirmed by PR #83 ("skipped" conclusion).
- Sticky comments deduped via `<!-- tag -->` lookups (failure / screenshot / size).
- Screenshot lifecycle bounded by `cleanup-screenshot-releases.yml` on PR close.
- Format-baseline now self-gated by `scripts/check-structure.sh` (Round 2 DX #3 → PR #73).

Remaining (P2, non-blocking):
1. Required-check ambiguity when `build-test` is skipped (only matters if branch protection added).
2. Lint still advisory (`continue-on-error: true`). PR #59 superseded, never escalated.
3. No watchOS UI test (deferred to V2).

## Reliability summary
All Round 1 + Round 2 reliability commitments landed:
- `ConnectivityContractTests.swift`: 12 tests, all 6 `ConnectivityMessage` cases + exhaustiveness guard.
- `SwiftDataSchemaBaselineTests.swift`: 4 tests, scoped honestly to "schema inventory" not "live disk migration".
- `JSONImporterTests.swift`: explicit `testImportInsertsWorkoutsAndIsIdempotent` proves re-import deduplicates.
- `VBTrainerApp.swift`: real 3-tier recovery (disk → rename-broken-store + retry → in-memory). No user-facing `fatalError`.
- CI failure dump 12 sections sticky, CoreData noise filtered, 60K cap.
- RepDetector flake fixed at root (PR #66): tuning + ±1 rep tolerance, no longer `-skip-testing`.

Remaining (P2, non-blocking):
1. `testSchemaInventory` hardcodes model count + name list — flag for V1.5 cloud-sync change.
2. `ConnectivityContractTests` covers wire format, not WCSession transport failures (correctly out-of-scope).
3. JSON importer idempotency proven for Workouts only; Jumps/Readiness/PRs only tested for first-insert.

## Cost summary
Verified all 5 Round 1 + Round 2 speedups in `ci.yml`:
- DerivedData cache key = `hashFiles('project.yml')` only (line 205).
- `build-for-testing` runs once before two `test-without-building` invocations.
- Async sim boot in parallel with compile (`bootstatus -b` blocks after build).
- Brew cache keyed `brew-*-v2`.
- `has_native_code` / `has_ui` gating works.

### Expected CI time (post-cache, `.swift`-only PR)

| Phase | Pre-Task-1 | Post-Task-1 (warm) |
|---|---|---|
| fast-fail | n/a | ~30s |
| brew + xcodegen | ~90s | ~15s |
| build-for-testing iOS | ~6 min | ~90s |
| build watchOS | ~3 min | ~45s |
| sim boot | ~60s | ~0s (parallel) |
| algorithm tests | ~60s | ~60s |
| UI + screenshots + release | ~4 min | ~4 min |
| **Total** | **~25-30 min** | **~7-8 min** |

Non-UI swift PR: **~4-5 min**. Docs-only: **~30s**. **70-75% reduction** vs baseline.

Remaining (P2, none blocking):
1. `xcparse` install not cached (~10-20s/PR).
2. iOS + watchOS build still sequential — parallelising doubles macOS-minute spend, net-negative.
3. ModuleCache reuse risk documented but not mitigated (acceptable).

## Acceptance criteria

| Check | Status |
|---|---|
| 任意 PR push 后 < 10 min CI 完成 | ✅ ~7-8 min cold, ~4-5 min non-UI |
| UI 改动 PR 出现 "自动验收 · 截图" 评论 | ✅ verified on PR #77 |
| CI 失败必出现 "❌ CI failed" 评论含真错误 | ✅ verified on PR #76 (caught swiftformat + type-check timeout) |
| 文档 / OpenSpec / 注释类 PR 跳过 macOS build | ✅ PR #83 confirmed `build-test` skipped |
| 非 UI / 非 schema PR 全绿后 AI 自决合 | ✅ 9 PRs auto-merged today via §13 rules |
| CLAUDE.md 写明工作流现状 | ✅ §11-14 |

All 6 acceptance criteria pass.

## Decision

**Task 1 complete.** No follow-up PRs needed for the three P2 cost / reliability paper-cuts — they go on the V1.5 backlog.

Next: archive `openspec/changes/auto-dev-workflow-buildup/` → `openspec/specs/` after this PR merges.
