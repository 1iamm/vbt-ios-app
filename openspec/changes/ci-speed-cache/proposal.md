# Proposal: CI 加速（Homebrew 缓存 + 条件 UI test）

## Why

PR #54（mandate 持久化）和 PR #55（haptic 改动 ~80 行）都跑了完整 ~10 min macOS pipeline，**其中 ~5-7 min 花在它们根本不需要的 UI test 上**。用户 explicitly 说"流水线慢"。这是 Task 1 的 PR #6（速度优化），优先级提到前面。

## What Changes

`.github/workflows/ci.yml`:

1. **Detect change scope** step（新）：用 github-script 调 `pulls.listFiles` 拿 PR diff，匹配 UI/build-affecting 路径 regex，输出 `has_ui = true/false`
2. **Cache Homebrew downloads**：`~/Library/Caches/Homebrew/{downloads,api}` → 每次 brew install 跳过 bottle 下载（~30s 省）
3. **条件跳过 5 个 step**（当 `has_ui != true`）：
   - Reset simulator before UI tests
   - Run UI tests（~5 min 省）
   - Extract screenshots from xcresult（~30s 省，跳过 brew install xcparse）
   - Publish screenshots as GitHub release asset
   - Post screenshot summary comment to PR
   - Upload xcresult bundle (raw)

## UI / build-affecting 路径正则

匹配任一即认为 PR 影响 UI / build：

```
^VBTrainer/Views/
^VBTrainerWatch Watch App/Views/
^VBTrainerWatch Watch App/Sensors/
^Shared/Theme/
^Shared/Models/
^VBTrainer/App/
^VBTrainerWatch Watch App/App/
^Tests/UITests/
^Shared/Extensions/.+UITestMode
^project\.yml$
```

不匹配的（→ skip UI test）：
- `.github/workflows/**`
- `scripts/**`
- `openspec/**`
- `.claude/**`
- `*.md`
- `Shared/Algorithms/**`、`Shared/Services/**`（unit test 仍跑）

## Capabilities

### Modified Capabilities
- `ci-fast-fail`（PR #2 引入）：扩展为含 scope detection

## Impact

- 文档 / OpenSpec / CI-only PRs：CI 时间从 ~10 min → **~3-4 min**（Static + Build + algorithm tests，无 UI test / 截图 pipeline）
- UI/algorithm/schema PRs：仍跑完整流程（含截图）
- macOS 分钟数节省估计：**~50%**（多数 PR 是 CI/docs 类）

## Risk

- 如果 `Detect change scope` 误判（UI 改动被识别为 docs），UI test 不跑 → 漏检 UI 回归
- 防御：regex 倾向"宁可多跑"，匹配 `VBTrainer/App/`（app 入口）、`Shared/Models/` 等次级 UI 影响路径
- Fallback：用户随时手动 re-run workflow 跑完整 CI

## Exit Criteria

- 本 PR 自己 dogfood：本 PR 只动 `.github/workflows/ci.yml` + openspec，应被识别为 non-UI → UI test 步骤跳过 → CI < 4 min 完成
- 下个 UI-涉及的 PR 仍跑完整流程 + 出截图评论
