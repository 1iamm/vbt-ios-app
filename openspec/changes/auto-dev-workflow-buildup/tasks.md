# Tasks: 全自动 AI 协助开发工作流搭建

## PR 进度

- [x] **PR #49** SwiftLint + SwiftFormat + auto failure-log to PR (advisory mode) — merged `3d8be4e`
- [x] **PR #50** Linux fast-fail (structure + PR size) — merged `db5f0d6`
- [x] **PR #51** PR template + CODEOWNERS + Claude prompt upgrade — merged `ffd7306`
- [x] **PR #52** UITest target + Onboarding e2e + UI_TEST_MODE bypass — merged `9f42fd8`
- [x] **PR #53** Auto-extract UI test screenshots → per-PR release → comment — merged `fe73715`
- [x] **PR #54** (=PR #5.5) Persist mandate into CLAUDE.md + OpenSpec — merged `aaa51f4`
- [x] **PR #56** (=PR #6) CI 加速：brew 缓存 + 条件 UI test — merged `ae5ce1b`
- [ ] **PR #57** format-baseline trigger 改 push（in flight）
- [ ] **PR #58** 触发 format-baseline 全仓格式化（pending; needs #57 merged）
- [ ] **PR #59** lint 升 blocking + warnings as errors（pending; needs #58）
- [ ] **PR #7** Watch 端静态截图 + visual diff baseline（pending）
- [x] **PR #9 Round 1** 3-agent 终审 — completed 2026-05-13，**NO PASS**，findings 归 `round1-review.md`
- [ ] **PR #60-#66** Round 1 findings 修复批次：
  - [ ] #61 docs-only skip build (DX F8 + Cost #2)
  - [ ] #62 DerivedData cache (Cost #1)
  - [ ] #63 失败 dump 完整化 + sticky failure comment (DX F1-F5)
  - [ ] #64 build-for-testing 拆分 + sim boot 并行 (Cost #3)
  - [ ] #60 SwiftData migration 测试 (Reliability #1)
  - [ ] #65 WatchConnectivity 契约测试 (Reliability #3)
  - [ ] #66 修 RepDetector testCleanFiveReps 根因 (Reliability #4)
- [ ] **PR #9 Round 2** 重审，目标 PASS

## 验收标准

- [ ] 任意 PR push 后 < 10 min CI 完成（缓存生效后）
- [ ] UI 改动 PR 必出现"自动验收 · 截图"评论（dogfood：PR #53 自己应能产出）
- [ ] CI 失败必出现"❌ CI failed"评论含真错误（不需要查 Actions 页）
- [ ] 文档 / OpenSpec / 注释类 PR 跳过 macOS build（< 1 min 完成）
- [ ] 自动 merge 规则：非 UI / 非 schema PR 全绿后 AI 自决合
- [ ] CLAUDE.md 写明工作流现状，新会话开起来 5 行内进入状态

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
