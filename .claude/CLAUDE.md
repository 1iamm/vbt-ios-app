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

### V2 愿景（未启动）
**AI 介入分析、推断、动态调整计划。**

- AI 训练前推断状态
- AI 训练中实时调整
- AI 训练后复盘对话
- AI 周期化计划生成
- 私教 SaaS（B2B2C）
- Keep / 训记数据导入

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

### 内容/营销相关
- ❌ 不要把代码 / PRD / 营销策略发到公司内网或 IM
- ❌ 不要在公开内容里提及用户的真实公司
- ❌ 不要用美团 / 公司邮箱做任何与本项目相关的注册

### Git 相关
- ✅ 本仓库 commit 自动用个人邮箱 `liam1012052510@gmail.com`（local config 已设）
- ❌ 不要 push --force 主分支
- ❌ 不要在 commit message 暴露任何公司信息

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

## 文档版本

- 2026-05-08 v1.0：初版，基于 Phase 0 完成时点
