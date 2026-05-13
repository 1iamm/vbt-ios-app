# Contributing to VBTrainer

> 这个文件给所有贡献者（包括将来的你自己）。
> 项目主背景看 `.claude/CLAUDE.md` 和 `README.md`。这里只讲 **PR 工作流** 和 **CI / Claude 互动**。

---

## PR 流程

1. 从 `main` 切分支：`git checkout -b <type>/<short-name>`
   - `type` ∈ `feat / fix / chore / docs / refactor`
2. 改代码 → 本地至少跑通 iOS + watchOS 编译（见下方命令）
3. `git push -u origin <branch>` → `gh pr create`
4. CI 跑两条：
   - **`CI / build-test`** — 必绿，挡合并
   - **`Claude / claude`** — 自动 review，挂了不挡合并
5. 默认 squash-merge + 删分支（CLAUDE.md 已写明）

---

## CI 在跑什么

### `.github/workflows/ci.yml` （macos-26）
每个 PR 自动跑：
- `xcodegen generate` —— 从 `project.yml` 重新生成 `.xcodeproj`
- `xcodebuild build` iOS + watchOS 两端 sim build（无签名）
- `xcodebuild test -only-testing:VBTrainerTests` —— 跑 `Tests/AlgorithmTests/`

**CI 不做的事**：
- ❌ 不跑 XCUITest / UI E2E（太慢、太贵、模拟器在 CI 不稳）
- ❌ 不出 `.ipa` / 不上 TestFlight（个人证书 7 天，本地 Archive）
- ❌ 不验证 design token JSX（本地手动同步 `vbt-tokens.jsx` ↔ `Shared/Theme/Tokens.swift`）

### `.github/workflows/claude.yml` （ubuntu-latest）
- PR 开 / 更新 → Claude 自动 review，按 `.claude/CLAUDE.md` 的标准
- 评论里写 `@claude ...` → Claude 互动写代码

---

## 跟 `@claude` 互动

在 PR 评论或 review 评论里直接 `@` 它。它会读 `.claude/CLAUDE.md`、PR diff、然后动手。

**有用的例子**：

```
@claude 这个新加的 BarVelocityCalculator 没单元测试，补 3 个 case：静止、匀速、加速。
```

```
@claude CI 上 watchOS build 失败了，看一下日志，修 Shared/ 里的跨端问题。
```

```
@claude 把 PlanViewModel 拆成 PlanViewModel + PlanQuery 两个文件，提到独立 commit。
```

```
@claude 我在算法里加了个常量 0.85，帮我加论文引用注释（参考 Shared/Algorithms/Citations.swift 的格式）。
```

**没用的例子**（别这样问）：

```
@claude 这个 PR 怎么样？      # 太模糊
@claude 帮我设计 V2 的 AI 模块  # 不是单 PR 范围
@claude 帮我跑测试           # 它不能直接跑 macOS xcodebuild
```

---

## Token 轮换（**重要**）

`claude.yml` 用的是 **Claude Pro/Max 订阅 OAuth token**，目前没有自动 refresh。
**大概每 1–2 周** token 会过期，`Claude / claude` job 会 401 失败。

修复步骤：
```bash
# 在你本地（已登录 Claude Code 的机器）
claude setup-token
# 复制输出的 token

# 然后在 GitHub:
# Repo → Settings → Secrets and variables → Actions
# 编辑 CLAUDE_CODE_OAUTH_TOKEN，粘贴新 token，Update
```

OAuth 过期不阻塞合并 —— `CI / build-test` 是唯一必绿的 check。

---

## 本地命令速查

```bash
# 重新生成 Xcode project（改了 project.yml 必跑）
xcodegen generate

# iOS sim build（无签名，跟 CI 一致）
xcodebuild -project VBTrainer.xcodeproj -scheme VBTrainer \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

# watchOS sim build
xcodebuild -project VBTrainer.xcodeproj -scheme "VBTrainerWatch Watch App" \
  -sdk watchsimulator -destination 'generic/platform=watchOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

# 跑算法单元测试
xcodebuild test -project VBTrainer.xcodeproj -scheme VBTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:VBTrainerTests
```

---

## 关于 macOS runner 分钟

- 私有 repo + Free 套餐 = 每月 2000 总分钟，**macOS 算 10× → 实际 200 macOS 分钟**
- 一次完整 CI ≈ 8–12 分钟 → 月 ~20 个 PR 就用光
- 如果不够用：把 repo 切 public（无公司信息，可公开）→ macOS 分钟无限免费

<!-- ci smoketest 2026-05-13 -->
