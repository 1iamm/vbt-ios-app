# Proposal: 全自动 AI 协助开发工作流搭建

## Why

用户希望"我提 idea → AI 写代码 → CI 全自动验证 → 自动截图 + PR 评论 → 我看图点 Merge"成为闭环，**人工介入只在 UI 决策点**。早期开发流程是 push 完手动跑 `xcodebuild` 自己看输出，这次任务把它工程化。

## What Changes

按 PR 序：

- **PR #49** ✅ — SwiftLint + SwiftFormat 工具链 + 失败日志自动贴 PR 评论
- **PR #50** ✅ — Linux fast-fail（项目结构检查 + PR 大小报警），省 macOS 分钟
- **PR #51** ✅ — PR 模板 + CODEOWNERS + Claude bot prompt 升级（分 review / @claude 写代码两模式）
- **PR #52** ✅ — `VBTrainerUITests` target + Onboarding e2e + `-UI_TEST_MODE` 启动开关 + UI test CI job
- **PR #53** ⏳ — xcresult 截图自动 extract → per-PR Draft Release → 评论嵌入 + Claude bot 改 `@mention-only` 触发（取消每 PR 自动 review，省时省钱）
- **PR #5.5** ← 本 change — 把约定写进 CLAUDE.md + OpenSpec 持久化
- **PR #6** — CI 加速（DerivedData 缓存 + Homebrew 缓存 + 条件 UI test 跳过 docs-only PR）
- **PR #7** — Watch 端静态截图 + visual diff baseline 比对（main 当 baseline，PR 算像素差）
- **PR #8** — format-baseline trigger 改 push、lint 升级为 blocking（drop continue-on-error）、warnings as errors
- **PR #9** — 3-agent 终审（DX / 可靠性 / 成本）确认流水线整体过关

## Capabilities

### Added Capabilities
- `ci-fast-fail`: Linux 上 30s 内挂掉的违规
- `ci-screenshot-pipeline`: XCUITest screenshots → release → PR comment 全链路
- `ci-auto-merge-rules`: AI 按文件路径判断是否自决合并（非 UI 自决；UI 等用户）
- `ci-failure-triage-comment`: build/test 失败时自动 dump 关键 log 到 PR 评论（让无 token 的 AI 也能 debug）

### Modified Capabilities
- `dev-loop`（既有的"AI 写代码 + Claude review"）— 加入截图自动 surface

## Impact

- 仅触动 `.github/workflows/`、`scripts/`、`project.yml`、`Tests/UITests/`、`Shared/Extensions/`
- 主应用代码仅微调（OnboardingView 加 accessibilityIdentifier、UI_TEST_MODE 跳过 HealthKitPermissionView）
- 不影响线上用户体验（`-UI_TEST_MODE` 启动参数线上不会传）

## Exit Criteria

3 个 agent 评审通过：
- **DX agent**：从云端 Claude 视角看，PR 失败时能否 5 分钟内自我诊断 + 修复
- **可靠性 agent**：CI 是否能消除"测了过却线上崩"的盲点（核心场景必有 e2e 截图）
- **成本 agent**：每 PR macOS 分钟数 < 8 min（缓存生效后）；批量 docs PR 不跑 macOS
