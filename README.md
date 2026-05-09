# VBTrainer

> Apple Watch + iPhone 的 VBT（基于速度的力量训练）数据采集与复盘工具。
> V1 让用户自己当教练，V2 接入 AI 当私教。

---

## 项目状态

- **当前阶段**：Proposal 1 — 项目脚手架（已完成，已验证编译通过）
- **后续阶段**：见 `openspec/changes/`，按 OpenSpec 流程串行推进

---

## 前置环境

| 项目 | 版本 | 当前状态 |
|---|---|---|
| macOS | ≥ 14（已验证 15.3.2） | ✅ |
| Xcode | 16.0+ | ✅ 已装在 `~/Downloads/Xcode.app` |
| iOS Simulator runtime | 18.0 | ⏳ 用户后台下载中（不阻塞编译） |
| watchOS Simulator runtime | 11.0 | ⏳ 后台下载中 |
| Apple Developer 账号 | 免费个人账号 | ✅ 美区 ID |
| Apple Watch | Series 7+ | ✅ 已配对 |
| `xcodegen` (Homebrew) | 2.45+ | ✅ 已装 |
| `openspec` (npm) | 1.2+ | ✅ 已装 |

> **注意**：Xcode 还在 `~/Downloads/`，建议拖到 `/Applications/`。
> 拖完后跑 `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`，否则系统级 `xcodebuild` 不可用（但用 Xcode GUI 不受影响）。

---

## 部署目标

- **iOS 17.0+** / **watchOS 10.0+**
- 原 PRD 写的是 iOS 16 / watchOS 9，但 SwiftData `@Model` 宏强制要求 iOS 17 / watchOS 10。Series 7 全部支持到 watchOS 11，所以零用户损失。

---

## Bundle ID & 签名

| Target | Bundle ID |
|---|---|
| iOS App | `com.vbtrainer.app` |
| watchOS App | `com.vbtrainer.app.watchkitapp` |
| 单元测试 | `com.vbtrainer.app.tests` |

签名走个人证书（Personal Team），仅供自用真机部署。**7 天证书过期后需重新部署**。上架 App Store 需要付费 Apple Developer（¥99/年），V1 末再考虑。

### 一次性签名配置

`xcodegen generate` 会重写 `.pbxproj`，每次都会冲掉 Xcode UI 里手选的 Team。所以 Team ID 通过 `Signing.xcconfig` 持久化（首次 clone 后做一次）：

```bash
# 1. 编辑 Signing.xcconfig，填你的 Team ID（10 位字母数字）
#    Team ID 在 https://developer.apple.com/account → Membership 查
nano Signing.xcconfig
# 改成： DEVELOPMENT_TEAM = ABC123XYZ4

# 2. 让 git 忽略你的本地修改（Team ID 不进 commit）
git update-index --skip-worktree Signing.xcconfig

# 3. 现在 xcodegen 生成的 project 自动带正确 Team
xcodegen generate
```

之后每次跑 `xcodegen generate` 不再需要任何手动操作。

---

## 打开 / 编译

```bash
# 1. 生成（或重新生成）.xcodeproj — 注意：源码改动不需要重新生成，
#    但是新增/删除 .swift 文件后必须重跑 xcodegen。
cd ~/workspace/vbt
xcodegen generate

# 2. 用 Xcode 打开
open VBTrainer.xcodeproj

# 3. 在 Xcode：
#    - Signing & Capabilities → Team → 选你的 Personal Team（必须先在 Xcode 设置里登录 Apple ID）
#    - 选 scheme：VBTrainer 或 VBTrainerWatch Watch App
#    - ⌘B 编译
```

**注意**：iOS scheme 默认会带 Watch 依赖触发完整编译。如果 watchOS 11 simulator 还没下完，会报错"watchOS 11.0 must be installed"。两个解决方案：
1. 等 simulator 下完
2. 临时只编 iOS：在 Xcode 选 "VBTrainer" target → Build for Running → 选 iPhone simulator/device

---

## 真机部署（推荐：核心算法必须真机测）

模拟器的 IMU 数据是假的，**所有 Rep 识别 / 速度计算 / CMJ 都必须在真机验证**。

```text
1. iPhone 用数据线连 Mac
2. iPhone：设置 → 隐私与安全性 → 开发者模式 → 开启 → 重启
3. Apple Watch：和 iPhone 配对的状态自动可用
4. Xcode 顶部设备选择器：选你的 iPhone（不是 simulator）
5. 第一次部署会要求：iPhone 设置 → 通用 → VPN与设备管理 → 信任你的开发者证书
6. ⌘R 运行 → iPhone + Watch 都会自动安装并启动 App
```

7 天后证书过期，App 启动会闪退 → 重跑 ⌘R 重新部署即可。

---

## 项目结构

```
vbt/
├── PRD.md                              # 产品需求文档（不要随便改）
├── README.md                           # 本文件
├── project.yml                         # XcodeGen 配置（修改后跑 xcodegen generate）
├── VBTrainer.xcodeproj                 # 由 xcodegen 自动生成，不要手编
├── VBTrainer/                          # iOS App target
│   ├── App/VBTrainerApp.swift          # @main 入口
│   ├── Views/RootView.swift            # 占位首页（Proposal 5 替换）
│   ├── Services/                       # （Proposal 4+ 填充）
│   └── Resources/                      # AppIcon、Localizable.xcstrings
├── VBTrainerWatch Watch App/           # watchOS App target
│   ├── App/VBTrainerWatchApp.swift
│   ├── Views/WatchRootView.swift       # 占位（Proposal 3 替换）
│   ├── Sensors/                        # CMMotionManager / HealthKit (Proposal 2)
│   ├── Algorithms/                     # Rep / Velocity / VL / CMJ (Proposal 2)
│   ├── Services/                       # WatchConnectivity (Proposal 4)
│   └── Resources/
├── Shared/                             # 两个 target 共享
│   ├── Models/                         # SwiftData @Model 全集
│   ├── Theme/                          # Tokens.swift（颜色/字体/间距/圆角）
│   ├── ExerciseLibrary/                # 30 个动作元数据
│   ├── Citations/                      # 论文引用
│   └── Extensions/                     # Color+Hex 等
├── Tests/                              # 单元测试（Proposal 2 写算法测试）
├── design/                             # Claude Design 导出的设计稿
│   ├── iphone/vbt-iphone/              # 含 vbt-tokens.jsx 设计 token 来源
│   └── watch/vbt/                      # watchOS 设计稿
├── openspec/                           # OpenSpec 工作区
│   ├── changes/foundation-scaffold/    # Proposal 1（已完成）
│   └── ...                             # 后续 proposals
└── .claude/                            # OpenSpec slash commands
```

---

## OpenSpec 工作流

每个有意义的功能模块都是一个 "change"。按以下流程推进：

```bash
# 创建新 change
openspec new change "feature-name"

# 查看状态
openspec status --change "feature-name"

# 写完所有 artifacts 后查看进度
openspec status --change "feature-name" --json

# 用 Claude Code 自动驱动：
#   /opsx:propose "..."    生成 proposal/design/specs/tasks
#   /opsx:apply            执行 tasks.md 里的 checklist
#   /opsx:archive          完成后归档到 openspec/specs/
```

每个 change 包含 4 个 artifact：
- `proposal.md` — Why & What
- `design.md` — How（架构、决策、权衡）
- `specs/<capability>/spec.md` — 需求规格（SHALL / WHEN-THEN）
- `tasks.md` — 可执行任务清单（带 checkbox）

---

## V1 路线图（OpenSpec changes 串行）

| Proposal | 状态 | 描述 |
|---|---|---|
| 1. foundation-scaffold | ✅ 完成 | Xcode 工程 + Tokens + 全部 SwiftData 模型 + 30 动作 + 论文引用 |
| 2. watch-sensors-algorithms | ✅ 完成 | CMMotion 100Hz + HKWorkoutSession + Rep/Velocity/VL%/CMJ 算法 + 单测 |
| 3. watch-ui | ✅ 完成 | Watch 端 14 屏 + 智能震动反馈 + Digital Crown |
| 4. connectivity-storage | ✅ 完成 | WatchConnectivity 双端 + WorkoutStore/JumpTestStore/ReadinessStore |
| 5. iphone-today-history | ✅ 完成 | iPhone 4-Tab + Today + History + 综合时间轴图表 + 心率区间环 |
| 6. iphone-plans-profile-onboarding | ✅ 完成 | Plans 模板 CRUD + Profile + 5 步 Onboarding + 论文清单 |
| 7. healthkit-readiness | ✅ 完成 | HealthKit 异步读取 + Readiness Score + 7 天基线 + 单测 |
| 8. trends-prs | ✅ 完成 | 长期趋势 4 图 + LVP/e1RM + PR 自动检测 + PR 列表 |
| 9. plan-execution-sync | ✅ 完成 | iPhone → Watch 模板下发 + Watch 今日计划展示 |
| 10. polish-export | ✅ 完成 | CSV/JSON 导出 + ShareSheet 集成 + 终验编译 |

---

## 设计 token 来源

设计 token 的唯一真源（single source of truth）是
`design/iphone/vbt-iphone/project/vbt-tokens.jsx`。

`Shared/Theme/Tokens.swift` 是它的 Swift 表达。修改 token 时**两边同步改**，否则代码和设计稿会漂移。

颜色规则：
- 中性色（label / secondary / bg / card）→ SwiftUI 系统语义色，自动适配深浅模式
- 强调色 + 数据色（accent / 心率 / 速度 / VL / 睡眠）→ 固定 hex（在两种模式下视觉一致）

---

## 论文引用

V1 引用了 18 篇关键论文，全部列在 `Shared/Citations/Citations.swift`。每个算法相关常量（V1RM、VL 阈值等）的赋值上方都有 `/// Reference: Citations.xxx` 风格注释，便于追溯。

设置页（Proposal 6）会展示论文清单 + 点击跳转 URL。

---

## 模拟器还在下载怎么办

不阻塞写代码：
- ✅ Swift 文件可以正常编辑、可以语法检查
- ✅ `xcodebuild -sdk iphoneos` 可以编译验证（不需要 simulator）
- ❌ 不能在 simulator 跑 App
- ❌ 不能用 SwiftUI Preview（需要 simulator 渲染）

下载完成后 simulator 自动可用，无需手动操作。watchOS 11.0 simulator 必须下完才能跑 watchOS scheme。

---

## 反馈与下一步

完成当前 proposal 验收后，启动下一个 proposal 之前请：
1. 检查 `openspec/changes/<name>/tasks.md` 是否所有 task 都打勾
2. `openspec status --change <name>` 显示全部 done
3. 真机或 simulator 跑一下，确认占位界面能起
4. 给我（Claude Code）确认 → 我开始下一个 proposal

完整产品规格见 [PRD.md](PRD.md)。
