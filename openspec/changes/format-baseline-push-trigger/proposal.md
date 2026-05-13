# Proposal: format-baseline.yml 加 push trigger

## Why

`format-baseline.yml` 当前只接受 `workflow_dispatch`（手动从 Actions tab 点击）。**云端 Claude 没有 workflow_dispatch 工具**，所以这个工作流一直没能被自动触发。结果：

- PR #49 落地 SwiftFormat 配置时，advisory 模式保留
- 自那以后所有 PR 都跑 `swiftformat --lint` 输出违规警告但不挂 CI
- 现存 .swift 文件从来没被批量 normalize
- 一年下来违规累积，token 系统纸面存在

需要一个**云端 Claude 能触发**的方式跑 baseline。

## What Changes

- `.github/workflows/format-baseline.yml`：
  - 加 `push` trigger，filter `format-baseline/*` 分支
  - 自动 commit 的 message 加 `[skip ci]` 防止 push 触发自己 → 无限循环
  - 加 if-condition 防御：bot 自己的 commit 永不再跑（即使 [skip ci] 失效）
  - checkout ref 兼容两种触发路径：`inputs.branch || github.ref_name`

## 触发方式（合并本 PR 后）

```bash
git checkout main
git checkout -b format-baseline/2026-05-init
git push -u origin format-baseline/2026-05-init
# Workflow auto-runs on push, formats all .swift files, commits back
# to format-baseline/2026-05-init with [skip ci]
```

之后从该分支开 PR → 合并到 main → 现存代码完全 normalize。

## Capabilities

### Modified Capabilities
- `ci-format-baseline-helper`

## Impact

- 仅 workflow 文件改动
- 不影响 main 上的任何代码
- 不影响 ci.yml（pull_request 触发不变）

## Exit Criteria

- 本 PR 合并后，push `format-baseline/<anything>` 分支自动触发 SwiftFormat 应用 + 回提
- 第二次 push 同分支（已经 normalized）无 commit，安静退出
