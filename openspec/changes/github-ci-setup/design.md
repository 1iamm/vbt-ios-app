# Design: GitHub CI + Claude Code

## 架构

```
PR 上来
│
├── ci.yml                      (macos-26, 必跑)
│   ├── checkout
│   ├── brew install xcodegen
│   ├── xcodegen generate
│   ├── xcodebuild build (iOS sim)
│   ├── xcodebuild build (watchOS sim)
│   └── xcodebuild test -only-testing:AlgorithmTests
│
└── claude.yml                  (ubuntu-latest, 触发条件多)
    ├── pull_request(opened/synchronize) → 自动 review
    ├── issue_comment(@claude)            → 互动
    └── pull_request_review_comment(@claude)
```

## 关键选择

### 为什么 ci.yml 不跑签名 / 不出 ipa
- 用的是个人 Personal Team 7 天证书，证书私钥不上 CI（安全 + 7 天会过期没意义）
- CI 只做 `CODE_SIGNING_ALLOWED=NO`，跑 sim build 验证编译
- Release 仍是用户本地 Xcode Archive

### 为什么单元测试只跑 AlgorithmTests
- 当前 `Tests/AlgorithmTests/` 是唯一存在的 test target
- UI 测试当前没写（CLAUDE.md 明说"UI 不写测试"）
- `-only-testing:AlgorithmTests` 明确范围、不依赖未来加新 target 的命名

### 为什么 claude.yml 跑 ubuntu 不跑 macOS
- Claude Code Action 只读 diff、commit 代码，不编译
- ubuntu runner $0.008/min，macOS $0.048/min（2026 价）→ 6× 便宜
- macOS 分钟省给真正的 build

### 为什么 prompt 里指向 .claude/CLAUDE.md
- 让 CI 上的 Claude 自动加载项目记忆：论文引用约束、SwiftData schema 注意、Shared/ 跨端检查
- 不重复写一份项目背景在 workflow yml 里

### 触发条件的精细化
`claude.yml` 的 `if`:
```yaml
if: |
  github.event_name == 'pull_request' ||
  (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
  (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude'))
```
- PR 开/更新 → 自动审一次
- 任何评论里出现 `@claude` → 互动
- 不在 push to main 触发（main 已合并，没必要再审）

### 失败 = 阻塞合并
- ci.yml build 或 test 任一失败 → PR check 红 → 不合
- claude.yml 失败 → 不阻塞合并（review 是辅助，不强制）

## 依赖外部 secret

| Secret | 用途 | 怎么生成 | 轮换 |
|---|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | claude.yml 鉴权 | 本地 `claude setup-token` | 1–2 周一次 |

`secrets.GITHUB_TOKEN` 是 GitHub 自动注入的，不用配。

## 失败模式 + 应对

| 场景 | 表现 | 应对 |
|---|---|---|
| OAuth token 过期 | claude.yml 报 401 | 本地重跑 `claude setup-token` 更新 secret |
| macOS 分钟耗尽 | CI 排队 / 不跑 | 切 repo public（免费）或升级 GitHub 套餐 |
| xcodegen 失败 | ci.yml fail at "Generate" 步 | 改 project.yml，本地 `xcodegen generate` 验证 |
| sim 找不到设备 | "Could not find a destination" | runner 镜像升级了，更新 destination 字符串 |

## 不在本 change 范围

- M6 启动后再加：Supabase migration 验证 + edge function 测试（ubuntu runner，便宜）
- TestFlight 上传 / release 自动化（用户暂时手动 Archive）
- Snapshot testing（M5 后视情况）
