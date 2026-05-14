# Tasks: 全自动 AI 协助开发工作流搭建

## PR 进度

- [x] **PR #49** SwiftLint + SwiftFormat + auto failure-log to PR (advisory mode) — merged `3d8be4e`
- [x] **PR #50** Linux fast-fail (structure + PR size) — merged `db5f0d6`
- [x] **PR #51** PR template + CODEOWNERS + Claude prompt upgrade — merged `ffd7306`
- [x] **PR #52** UITest target + Onboarding e2e + UI_TEST_MODE bypass — merged `9f42fd8`
- [x] **PR #53** Auto-extract UI test screenshots → per-PR release → comment — merged `fe73715`
- [x] **PR #54** (=PR #5.5) Persist mandate into CLAUDE.md + OpenSpec — merged `aaa51f4`
- [x] **PR #56** (=PR #6) CI 加速：brew 缓存 + 条件 UI test — merged `ae5ce1b`
- [x] **PR #57** format-baseline trigger 改 push — merged earlier
- [x] **PR #58** 触发 format-baseline 全仓格式化 — merged earlier
- [x] **PR #59** lint 升 blocking + warnings as errors — superseded by Round 2 sub-PRs
- [x] **PR #9 Round 1** 3-agent 终审 — completed 2026-05-13，**NO PASS**，findings 归 `round1-review.md`
- [x] **PR #60-#66** Round 1 findings 修复批次（all merged）：
  - [x] #61 docs-only skip build (DX F8 + Cost #2)
  - [x] #62 DerivedData cache (Cost #1)
  - [x] #63 失败 dump 完整化 + sticky failure comment (DX F1-F5)
  - [x] #64 build-for-testing 拆分 + sim boot 并行 (Cost #3)
  - [x] #60 SwiftData migration 测试 (Reliability #1)
  - [x] #65 WatchConnectivity 契约测试 (Reliability #3)
  - [x] #66 修 RepDetector testCleanFiveReps 根因 (Reliability #4)
- [x] **PR #9 Round 2** 终审 — completed 2026-05-13/14，CONDITIONAL PASS，open items dispatched as #69-#76
- [x] **PR #69** build-for-testing + sim boot 并行（re-applied on PR #66） — merged `c4b32f0`
- [x] **PR #70** ProfileView accessibilityIdentifier — merged `d1734c7`
- [x] **PR #71** SwiftData crash-safe recovery (Reliability R2 #17) — merged `942f1aa`
- [x] **PR #72** cleanup-screenshot-releases workflow (Reliability R2 #19) — merged `17c51df`
- [x] **PR #73** format-baseline runs check-structure.sh (DX R2 #3) — merged `1ad4592`
- [x] **PR #74** Prerelease vs Draft text fix — merged `427a53c`
- [x] **PR #75** ci cache key hashes only project.yml (Cost R2 #C2-C3) — merged `56d731c`
- [x] **PR #76** velocity precision roundtrip test (IX R1 F15) — merged `fa67bf8`
- [ ] **PR #7** Watch 端静态截图 + visual diff baseline（pending — deferred to V2）
- [x] **PR #9 Round 3** 终审 2026-05-14 — **DX PASS · Reliability PASS · Cost CONDITIONAL PASS · 总体 PASS**，详 `round3-review.md`

## 验收标准 — Round 3 verified

- [x] 任意 PR push 后 < 10 min CI 完成（cold ~7-8 min，warm ~4-5 min for non-UI swift）
- [x] UI 改动 PR 必出现"自动验收 · 截图"评论（PR #77 验证）
- [x] CI 失败必出现"❌ CI failed"评论含真错误（PR #76 验证 — 抓到 SwiftFormat + type-check timeout）
- [x] 文档 / OpenSpec / 注释类 PR 跳过 macOS build（PR #83 验证）
- [x] 自动 merge 规则：非 UI / 非 schema PR 全绿后 AI 自决合（2026-05-14 一日 9 PR auto-merge）
- [x] CLAUDE.md 写明工作流现状（§11-14）

**Task 1 状态：CLOSED**（待归档到 `openspec/specs/`）

## 已完成的子能力

- ✅ `scripts/check-structure.sh`：5 条结构规则
- ✅ `.swiftlint.yml` + `.swiftformat`：风格基线
- ✅ `Shared/Extensions/ProcessInfo+UITestMode.swift`：UI test mode toggle
- ✅ `Tests/UITests/{UITestHelpers,OnboardingUITest}.swift`：示范 e2e
- ✅ `.github/workflows/format-baseline.yml`：一次性格式化 workflow
- ✅ `.github/workflows/ci.yml` `fast-fail` job：Linux 30s 检查
- ✅ `.github/workflows/ci.yml` "Post failure log" + "Post screenshot summary"：双 sticky 评论
- ✅ `.github/workflows/claude.yml`：分 review / @claude 写代码两模式，改 mention-only

## 未完成 / 后续

见 `tasks.md` 顶部 PR 列表。
