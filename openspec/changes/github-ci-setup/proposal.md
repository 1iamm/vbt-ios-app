# Proposal: GitHub CI + Claude Code PR Review

## Why

VBTrainer 目前没有任何 GitHub Actions 配置。每次 PR 上去后：
- 没有自动编译验证 → 容易把 iOS / watchOS 编译错误合到 main
- 没有自动跑 7 套算法单元测试 → 算法回归只能靠记得本地跑
- 没有 PR Review → 单人项目缺一道审查关，论文引用注释、SwiftData schema 变更、Shared/ 跨端影响都靠记忆

同时 Zexi 希望"我只给 idea，让 Claude Code + CI 帮我完成开发 + 测试"。
本 change 是这件事的**基础设施层**。

## What

1. 加 `.github/workflows/ci.yml`：每个 PR 自动 xcodegen + iOS build + watchOS build + algorithm tests。
2. 加 `.github/workflows/claude.yml`：每个 PR 触发 Claude Code Action 自动审查；PR 评论里 `@claude ...` 互动写代码。
3. 加 `CONTRIBUTING.md`：写明 `@claude` 的使用约定 + token 轮换流程。

**显式不做的事**（避免过度工程）：
- ❌ 不在 CI 里跑 XCUITest / 模拟器 E2E（macOS 分钟太贵 + 不稳）
- ❌ 不做接口测试自动生成（V1 无后端，留到 M6 上 Supabase 时）
- ❌ 不引入 fastlane / Bitrise / CodeMagic（单人项目过度工程）

## 决定的关键权衡

| 项 | 选 | 不选 | 原因 |
|---|---|---|---|
| 鉴权 | `CLAUDE_CODE_OAUTH_TOKEN`（订阅 token） | `ANTHROPIC_API_KEY` | Zexi 只有订阅，不愿额外付 API |
| Token 轮换 | 手动每 1–2 周 `claude setup-token` | 自动 refresh | issue #727 还没合 |
| macOS runner | `macos-26` | self-hosted | 个人 Mac 不挂 24h |
| Claude review runner | `ubuntu-latest` | macOS | Claude 只读代码，不编译，便宜 |
| 触发 | PR `opened` + `synchronize` + `@claude` 评论 | 每个 push | 省 token + 噪音少 |

## 已知约束

- macOS runner 在 private repo 上算 10× 分钟。Free 套餐每月 200 macOS 分钟。若超额 → 把 repo 切 public（无公司信息，可公开）或升级 GitHub 套餐。
- OAuth token 大约 1–2 周需手动轮换一次。CONTRIBUTING.md 里写明流程。
