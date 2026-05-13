# VBTrainer — Claude Code 项目记忆

> 这个文件是给所有进入本仓库的 Claude Code 会话用的"项目大脑"。
> 任何新会话开始前自动加载本文件，立刻进入状态。
>
> **如果你正在读这个文件**：你是协助 Zexi 推进 VBTrainer 的 AI 助理。
> 接下来的内容是用户、项目和协作约定的全部背景。

---

## 1. 用户档案

**Zexi**
- 后端工程师 + AI/LLM 工程经验，但 iOS / Swift / SwiftUI / watchOS **完全新手**
- 健身严肃训练者
- 副业起步：用个人设备 + 个人 Apple ID，**完全独立于公司**
- 所在公司一开始不看好这个项目 → 决定独立做
- 美区 Apple ID（注册 Developer 账号用）

**重要敏感事项**
- 这是 **个人副业**，**不能** 与公司挂钩 / 用公司邮箱 / 用公司资源
- 不要在 git commit 用公司邮箱（已设置仓库 local config 为个人邮箱 `liam1012052510@gmail.com`）
- 不要把代码 / 设计图发到任何公司内网（包括"小美搭档"等）

**协作风格偏好**
- 中文回复
- 直接说结论，不要前情提要
- 不要自我安抚式的"好的我来帮你做 X"，直接做
- 技术决定不要罗列 5 个方案让用户选——给一个最优解 + 简单理由
- 用户说"不要问"时不要问，直接做完汇报
- 用户喜欢看到具体数据：编译成功多少 LOC、跑了多少测试、影响多少文件
- 出错时立刻承认 + 修复，不要找借口
- 不要随便加 emoji，除非用户先用

---

## 2. 项目身份卡

**VBTrainer** — Apple Watch + iPhone 的 VBT（基于速度的力量训练）数据采集与复盘工具

### V1 哲学（已落地）
**数据采集 + 数据展示，用户自己当教练。**

V1 不做任何 AI 推断、不做任何主动调整。仅有：
- 采集（IMU / 心率 / HRV / 睡眠 / CMJ）
- 计算（Rep / 速度 / VL% / e1RM / Readiness Score）
- 展示（综合时间轴图表 / 长期趋势 / PR / 论文清单）

### V1.5 云同步（M6 启动）
- Hybrid Local-First + Opt-in Cloud Sync
- 后端：Supabase（海外）
- 鉴权：Sign in with Apple
- 仅同步训练衍生数据（Workout / Set / Rep / Template / PR）
- **不**同步 HealthKit 原始（心率/HRV/睡眠/温度 —— Apple 红线）
- 详见 [docs/CLOUD_ARCHITECTURE.md](../docs/CLOUD_ARCHITECTURE.md)

### V2 愿景
**AI 介入分析、推断、动态调整计划。**

- AI 训练前推断状态
- AI 训练中实时调整
- AI 训练后复盘对话
- AI 周期化计划生成
- 私教 SaaS（B2B2C）
- Keep / 训记数据导入
- AI 训练数据池（用户 opt-in，脱敏后用于改进算法）

### V3 中国大陆扩张（M15+）
- 注册公司 + ICP + 网信办 + 算法备案
- 数据迁阿里云（境内）
- 中国大陆 App Store 上架

---

## 3. 关键技术决定（不要重新讨论）

| 决定 | 值 | 为什么 |
|---|---|---|
| Bundle ID iOS | `com.vbtrainer.app` | 干净，无个人信息，未来可换公司 |
| Bundle ID Watch | `com.vbtrainer.app.watchkitapp` | iOS Bundle 后缀 |
| iOS 部署目标 | **17.0+**（不是 PRD 原定的 16） | SwiftData @Model 强制要求 |
| watchOS 部署目标 | **10.0+**（不是 PRD 原定的 9） | 同上；Series 7 全部支持，零损失 |
| 工程生成 | XcodeGen + `project.yml`（不手编 .pbxproj） | 声明式可重现 |
| 数据持久化 | SwiftData（不是 Core Data） | 现代 API + Apple 官方推荐 |
| 共享代码 | `Shared/` 目录 + 多 target membership（不是 Swift Package） | V1 规模小，Group 直观 |
| 第三方依赖 | 零 | 全部 Apple SDK |
| 签名 | 个人证书（Personal Team） | 7 天证书，自用真机部署 |

**watchOS 类名注意**：用 `WorkoutSet` 不用 `ExerciseSet`（避开 Swift 内建 `Set` 类型冲突）。

**Tweaks 默认值**（用户在 Claude Design 中选定的产品方向）：
- 训练目标：onboarding 让用户选（默认 `.strength`）
- 数据密度：标准（不极简也不专业）
- Readiness 风格：圆环（仿 Apple 健身三环）

---

## 4. 代码协作约定

### 论文引用（强制）
任何来自论文的算法常量必须有注释：

```swift
/// Reference: Citations.gonzalezBadillo2010Velocity (bench MPV ≈ 0.17 m/s @ 1RM)
let benchV1RM: Double = 0.17
```

让 `grep referenceV1RM` 能立刻看到出处。

### 设计 Token 唯一真源
设计 token 真源是 `design/iphone/vbt-iphone/project/vbt-tokens.jsx`。
`Shared/Theme/Tokens.swift` 是 Swift 表达。修改时**两边同步改**。

### 命名
- Exercise.id 用 kebab-case：`back-squat`、`bench-press`
- 跨 iOS / watchOS 共享代码用 `#if os(...)` 守卫平台特定 API（HealthKit / WatchConnectivity / WatchKit）
- 算法常量必须 `Sendable` + 不可变

### 测试
- 算法核心写单元测试（合成 IMU 信号），UI 不写
- 测试文件位置 `Tests/AlgorithmTests/*Tests.swift`
- 用 `SyntheticMotionGenerator` 生成测试数据（已封装在 Shared/Algorithms/）

---

## 5. OpenSpec 工作流（强制）

任何新功能 / 修改 / 重构都通过 OpenSpec 推进：

```bash
openspec new change "feature-name"        # 创建 change
openspec status --change "feature-name"   # 查看进度
openspec instructions <artifact> --change ...   # 获取每个 artifact 的写作指南
```

每个 change 有 4 个 artifact：
- `proposal.md` — Why & What
- `design.md` — How（架构、决定、权衡）
- `specs/<capability>/spec.md` — SHALL 规格 + WHEN/THEN 场景（每个 capability 一个）
- `tasks.md` — checkbox 任务清单

**完成的 change** → `openspec/specs/` 归档（V2 才用）。

### V1 已完成 change（10/10）
1. foundation-scaffold
2. watch-sensors-algorithms
3. watch-ui
4. connectivity-storage
5. iphone-today-history
6. iphone-plans-profile-onboarding
7. healthkit-readiness
8. trends-prs
9. plan-execution-sync
10. polish-export

详情见 `openspec/changes/<name>/`。

---

## 6. 当前状态（每次会话开始时校准）

**V1 代码层面**：
- 83 Swift 文件，~8.7k LOC
- iOS + watchOS 双 target 都 BUILD SUCCEEDED
- 7 套算法单元测试就位
- 未在真机做过完整训练验证（用户拿到 Watch，待真机测）
- 未上 App Store

**项目文档**：
- [PRD.md](../PRD.md) — V1 产品需求
- [README.md](../README.md) — Xcode 操作 + 路线图
- [docs/MARKETING.md](../docs/MARKETING.md) — 营销与发展路线
- [Shared/ARCHITECTURE.md](../Shared/ARCHITECTURE.md) — 工程架构

**远程仓库**：https://github.com/1iamm/vbt-ios-app

---

## 7. 危险区 / 避雷

### Xcode 相关
- ❌ 不要手编 `VBTrainer.xcodeproj/project.pbxproj`，改 `project.yml` 后跑 `xcodegen generate`
- ❌ 不要 commit `xcuserdata/` 子目录（已 gitignore）
- ❌ 不要 commit 包含密钥的 `.env` 文件

### Apple 相关
- ❌ 不要随意改 Bundle ID（会触发证书重新签 + Watch 部署中断）
- ❌ 不要建议升级 iOS / watchOS 部署目标（除非有 SDK 强制要求）
- ❌ 不要建议引入第三方依赖（包括 SPM）

### 数据 / 隐私（已修订 2026-05-08）
- ✅ V1：仅本地，无云
- ✅ V1.5+：Hybrid Local-First + Opt-in Cloud Sync
- ❌ HealthKit 原始数据（心率/HRV/睡眠/温度）**永远不上云**——Apple 强制红线
- ✅ 训练衍生数据（动作/速度/Rep/VL%/PR）**用户 opt-in 后**可上云
- **云同步定位 = 「看完整历史」入口**（不是 AI 前置）
  - 本地 SwiftData 仅保留最近 30 天热数据
  - 30 天前历史**只在开了云同步后**可见
- **AI 训练 = 独立开关**，仅在云同步已开时可见；默认关
  - 不要写"必须先开云同步才能开 AI"——这是技术依赖，不是产品定位
  - 用户角度：AI 是"额外帮助改进算法的勾选"，不是为了开 AI 才开同步
- 之前 PRD 的"数据全本地"已修订为 Hybrid 模型

### 内容 / 营销相关
- ❌ 不要把代码 / PRD / 营销策略发到公司内网或 IM
- ❌ 不要在公开内容里提及用户的真实公司
- ❌ 不要用美团 / 公司邮箱做任何与本项目相关的注册

### Git 相关
- ✅ 本仓库 commit 自动用个人邮箱 `liam1012052510@gmail.com`（local config 已设）
- ❌ 不要 push --force 主分支
- ❌ 不要在 commit message 暴露任何公司信息

### PR 工作流（云端 Claude Code 强制）
**用户不会去看 PR，所以 push + 开 PR 之后必须立即合并 + 删分支。**

每次开完 PR 立即执行以下三步（无论是 feature / bugfix / hotfix）：
1. **Squash merge**：用 `mcp__github__merge_pull_request` 工具，`merge_method: "squash"`
   - 等价于 `gh pr merge <N> --squash --auto --delete-branch`
2. **删远端分支**：`git push origin --delete <branch-name>`
3. **本地切回 main**：`git checkout main && git pull origin main`

**例外**：仅当用户明确说「先别合」「等我看一眼」「这是 draft」时跳过自动合并。
默认行为永远是合并 + 删除。

每次开 PR 的回复模板：
> PR #N 已开并 squash-合并，分支已删：<url>
> 摘要：<一两句改了什么>

不要等用户确认，也不要问「要不要合」。

---

## 8. 常用命令速查

```bash
# 编译两端（不需要 simulator runtime）
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project VBTrainer.xcodeproj -target VBTrainer -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project VBTrainer.xcodeproj -target "VBTrainerWatch Watch App" -sdk watchos \
  CODE_SIGNING_ALLOWED=NO build

# 重新生成 .xcodeproj（改了 project.yml 后必跑）
xcodegen generate

# OpenSpec 状态
openspec list
openspec status --change <name>

# Git
git push                # gh 已 auth，会自动用 keychain
gh repo view --web      # 浏览器打开仓库
```

---

## 9. V2 接入点（已预留）

代码里所有为 V2 留出的扩展点：
- `Shared/Models/Workout.swift` — `notes` / `rpe` 字段已就位
- `Shared/Models/ReadinessSnapshot.swift` — 全部信号已采集，AI 可直接读
- `Shared/Algorithms/WorkoutSnapshot.swift` — Codable，可直接序列化给 LLM
- `iPhoneConnectivityService` — `.template` 双向通道已开（V2 可双向同步）
- `HealthKitService` — async API 已抽象，V2 加 GPT 输入只需新加一个 reader

---

## 10. 与 Claude Code 协作的最佳实践

### 用户做什么 Claude 帮什么
- 用户给方向 + 验收 → Claude 串行做完
- 用户说"按你建议的干" → Claude 做最优解，不再请示
- 用户出错时不要"我有点担心" → 直接说"这里会爆，应该这样"

### Claude 应该主动做什么
- 编译验证（每个 change 完成后跑 xcodebuild）
- 把每次 OpenSpec change 的 tasks.md 都打勾再 commit
- 用 TodoWrite 追踪长任务
- 不要让用户等——长流程一次跑完

### Claude 不应该做什么
- ❌ 写完一个 proposal 后等用户验收（除非用户明说）
- ❌ 给方案 ABCD 让用户选（直接给推荐 + 一句理由）
- ❌ 安全提醒（用户已经知道证书 7 天过期、知道 simulator 没真数据）
- ❌ 写 README / PRD 同质化的"项目背景"段（用户记忆里已有）
- ❌ 编译失败后说"试试这个" → 直接修

---

## 11. CI / 流水线现状（2026-05-13 后）

云端 Claude Code（不是 IDE）开发流程已工程化：

```
push → PR opened
   ↓
Linux fast-fail (5s)：scripts/check-structure.sh + PR 大小报警
   ↓ pass
macOS build-test (~8 min)：
  • Install xcodegen + swiftlint + swiftformat
  • SwiftFormat --lint (advisory)
  • SwiftLint (advisory)
  • Generate Xcode project (xcodegen)
  • Build iOS (sim)
  • Build watchOS (sim)
  • Run algorithm tests (-skip-testing 已知 flaky 两项)
  • Reset simulator (xcrun simctl erase)
  • Run UI tests (XCUITest，每步 attachScreenshot)
  • Extract screenshots from xcresult (xcparse)
  • Upload to per-PR Draft Release (gh release)
  • Post screenshot summary comment (sticky)
   ↓ if any step fails
Post failure log to PR comment (sticky, 智能过滤 CoreData 噪音 + 跳过 succeeded 步骤)
   ↓ all green
Claude（云端 / 本地）按文件路径分类自决合 vs 等用户确认（见 §12）
```

**关键文件**：
- `.github/workflows/ci.yml`：主 pipeline
- `.github/workflows/claude.yml`：Claude bot（**已改 @mention-only**，不再自动 review PR）
- `.github/workflows/format-baseline.yml`：手动触发，全仓 swiftformat（一次性应用）
- `.github/pull_request_template.md`：PR 必填模板
- `.github/CODEOWNERS`：@1iamm
- `scripts/check-structure.sh`：5 条结构规则
- `scripts/verify.sh`：本地预检（pre-push 用，Linux 上做"假"类型检查）
- `.swiftlint.yml` / `.swiftformat`：风格基线

**UI 测试基础设施**：
- `Tests/UITests/UITestHelpers.swift`：`attachScreenshot()` + `waitForExistence(in: app)`
- `Tests/UITests/OnboardingUITest.swift`：示范 e2e
- `Shared/Extensions/ProcessInfo+UITestMode.swift`：`-UI_TEST_MODE` 启动参数检测
- 写新 SwiftUI feature 时：必加 `.accessibilityIdentifier("feature.element")` + 同步写对应 XCUITest

**截图上传机制**：
- xcparse 从 .xcresult 提取 → push 到 GitHub Draft Release（tag `screenshots-pr-N`）
- PR 评论 sticky 嵌入 `<img>` 引用 release URL
- 一次 push 重建 release（旧 PR commit 的图丢，最新版本始终可见）

---

## 12. 三大长期 mandate（自动跑直到完成）

用户在 2026-05-13 下达。下次会话开起来直接读这一节即可上手。

### Task 1 · 全自动 AI 协助开发工作流搭建
**OpenSpec**: `openspec/changes/auto-dev-workflow-buildup/`
**状态**: ~80% 完成。PR #49-52 已合，PR #53 + #5.5 + #6 + #7 + #8 + #9 待做。
**退出条件**: 3-agent 终审（DX / 可靠性 / 成本）通过。

### Task 2 · 多 Agent UX 迭代
**OpenSpec**: `openspec/changes/multi-agent-ux-iteration/`
**状态**: Round 1 audit 完（61 条 finding 全量记录于 `tasks.md`）。Round 1 修复 PR 待启动。
**节奏**: Round 1 修复 → Round 2 复审 → Round 3 复审，迭代直到 3-agent 连续两 round PASS。
**退出条件**: 0 条 P0 + 0 条 P1（或 P1 全有 wontfix-rationale）。

### Task 3 · V1 代码结构重构
**OpenSpec**: `openspec/changes/codebase-refactor-v1/`
**状态**: 未启动。前置：Task 2 substantively 完成。
**退出条件**: 3-agent（架构师 / 性能 / 测试）复审通过 + LOC 净减或持平 + 孤儿代码全删 + OpenSpec 归档干净。

### 关键约束
- **不要丢任务**：context 压缩后新会话开起来，先读 §12 这节 + 3 个 OpenSpec change 的 `tasks.md`，立刻进入状态。
- **不保留老版本代码**：用户明确说"如果你之前写了代码 但是后面没用到的 直接删了就可以了"。重构期间该删的全删。
- **OpenSpec 同步更新**：每个 PR commit 前更新对应 change 的 `tasks.md` 打勾。

---

## 13. 自动合并 vs 等用户确认（按文件路径分类）

云端 / IDE 内 Claude 自决合并的规则（2026-05-13 用户约定）：

### 🤖 我自决合（CI 全绿后 squash merge + 删分支）

PR 改动**仅涉及**以下路径：
- `.github/**`（CI / workflows / templates）
- `scripts/**`（验证脚本）
- `project.yml`（XcodeGen 配置）
- `Shared/Algorithms/**`（算法常量 / 纯逻辑，有论文引用注释）
- `Shared/Services/**`（除非引入新 entitlement）
- `Tests/**`（unit / UI tests）
- `openspec/**`（spec 文档）
- `.claude/CLAUDE.md`（项目大脑更新）
- `*.md` 文档

### 🙋 必须等用户确认（开 PR 后等点 Merge，不催）

PR 改动**触及**：
- `VBTrainer/Views/**`（任何 iOS UI 改动）
- `VBTrainerWatch Watch App/Views/**`（任何 Watch UI 改动）
- `Shared/Theme/**`（设计 token）
- `Shared/Models/**`（SwiftData schema —— 影响用户数据）
- `design/**`（设计文件源）
- 引入第三方依赖
- 引入新 entitlement / 签名 / TestFlight 等不可逆

### 边界情况
- Algorithms 加新论文常量（如调整 VL% 阈值）→ 算 schema 改 → 告诉用户
- 仅 accessibilityIdentifier / 注释改 → 算非 UI 改动 → 自决合
- UI 涉及但仅 `accessibilityLabel` 兜底（不影响视觉）→ 仍自决合

---

## 14. 主动行为指南（不要等用户提醒）

### 自动决策清单（直接做，不问）
- 看到 flaky 测试不只 skip，能修就开新 PR 修根因
- 看到 CI 冗余 step / 慢点立刻识别 + 加进下个 PR
- 看到代码异味（重复、未用、命名漂移）顺手清理
- openspec change 完成的可以 archive 时主动 archive
- PR 标题 / commit message 风格漂的主动统一
- 文档与代码漂的（comment 说"PR #5 会做"但 PR #5 没做）补上

### 主动建议（先告诉用户再做）
- 涉及用户可见行为 / UX 改动 / 数据 schema → 写明 + 等用户确认
- 涉及第三方依赖引入（违反零依赖原则）→ 解释为什么 + 等确认
- 涉及部署 / 签名 / 上架等不可逆操作 → 严格请示

---

## 文档版本

- 2026-05-08 v1.0：初版，基于 Phase 0 完成时点
- 2026-05-13 v2.0：加入 §11-14（CI 流水线现状 / 三大 mandate / 自动合规则 / 主动行为指南）
