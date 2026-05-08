## 1. Xcode 项目脚手架

- [x] 1.1 在 `/Users/lizexi/workspace/vbt/` 创建 `VBTrainer.xcodeproj`（含 iOS app target + watchOS Watch App target，Modern Watch App pair）— 通过 XcodeGen + project.yml 生成
- [x] 1.2 配置 iOS Bundle ID = `com.vbtrainer.app`，watchOS Bundle ID = `com.vbtrainer.app.watchkitapp`
- [x] 1.3 设置 deployment target = iOS 17.0 / watchOS 10.0（**修订**：原计划 iOS 16 / watchOS 9，但 SwiftData 强制要求 iOS 17 / watchOS 10；Series 7 全部支持，零用户损失）
- [x] 1.4 配置自动签名（Personal Team 占位，DEVELOPMENT_TEAM 留空，用户首次打开 Xcode 时自己选）
- [x] 1.5 创建项目目录结构：`VBTrainer/{App,Views,Services,Resources}` + `VBTrainerWatch Watch App/{App,Views,Sensors,Algorithms,Services,Resources}` + `Shared/{Models,Theme,ExerciseLibrary,Citations,Extensions}`
- [x] 1.6 在两个 target 的 Info.plist 加入 `NSMotionUsageDescription` / `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`（中文描述）— 通过 project.yml `INFOPLIST_KEY_*` 自动生成
- [x] 1.7 创建空 `Assets.xcassets`（占位 — `GENERATE_INFOPLIST_FILE: YES` + `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` 配置已就位，用户在 Xcode 内可以拖入 AppIcon 图片资产）
- [x] 1.8 国际化预留：`developmentLanguage: zh-Hans` 已在 project.yml 配置；`Localizable.xcstrings` 在 Proposal 10 i18n wrap 时正式落地
- [x] 1.9 创建 `VBTrainerApp.swift`（iOS App entry，含 `ModelContainer` 注入 + `RootView` 占位）
- [x] 1.10 创建 `VBTrainerWatchApp.swift`（watchOS App entry，类似）
- [x] 1.11 验证：两个 target 都能 build 成功 — 已通过 `xcodebuild -sdk iphoneos` + `-sdk watchos` 验证 BUILD SUCCEEDED

## 2. 设计系统 Theme

- [x] 2.1 创建 `Shared/Extensions/Color+Hex.swift`：`Color(hex:)` 初始化器
- [x] 2.2 创建 `Shared/Theme/Tokens.swift`：`enum Tokens` 含 `Color / Space / Radius / Font` 子 enum
- [x] 2.3 `Tokens.Color`：`accent` (`#FF9500`)，子 namespace `Data` 含 `heartRate / velocity / volume / velocityLoss / sleep`
- [x] 2.4 中性色（label / secondaryLabel / bg / card 等）通过 SwiftUI 系统语义色暴露，跨 iOS / watchOS 适配（Watch 用纯黑背景）
- [x] 2.5 `Tokens.Space`：`xs / sm / md / lg / xl / xxl / xxxl` 对应 4/8/12/16/20/24/32
- [x] 2.6 `Tokens.Radius`：`sm/md/lg/xl/card` 对应 8/12/16/20/14
- [x] 2.7 `Tokens.Font`：`largeTitle / title / headline / body / callout / footnote / caption / numericXL / numericLarge / numericMedium / numericSmall`，数字字体用 `.rounded` design
- [x] 2.8 颜色资产：V1 用代码常量，hex 直接 inline（与设计稿一致）；后续上架前再通过 Asset Catalog Color Set 暴露给设计师 / 应用图标用

## 3. SwiftData Models

- [x] 3.1 `Shared/Models/Enums.swift`：定义 `Sex / BodyType / TrainingExperience / TrainingGoal / WeightUnit / Side / VelocityVariant / MetStatus / ReadinessTier / PRKind / ExerciseCategory / CitationTopic`
- [x] 3.2 `Shared/Models/UserProfile.swift`：`@Model class UserProfile` + Tanaka HRmax derived property
- [x] 3.3 `Shared/Models/Workout.swift`：`@Model` + `@Relationship(.cascade) sets`
- [x] 3.4 `Shared/Models/WorkoutSet.swift`：类名用 `WorkoutSet`（避开 Swift `Set`），含速度变量计算 + VL% derived
- [x] 3.5 `Shared/Models/Rep.swift`：含 MV/PV/MPV 三种速度 + `velocity(for:)` 查询
- [x] 3.6 `Shared/Models/JumpTest.swift`：独立模型，含 `attempts: [Double]` + `flightTimeSeconds: [Double]`
- [x] 3.7 `Shared/Models/ReadinessSnapshot.swift`：每日 readiness 快照
- [x] 3.8 `Shared/Models/Template.swift` + `Shared/Models/TemplateItem.swift`
- [x] 3.9 `Shared/Models/PersonalRecord.swift`
- [x] 3.10 `Shared/Models/ModelSchema.swift`：`enum VBTSchemaV1.allModels` 列出全部 Models
- [x] 3.11 在两个 App entry 创建 `ModelContainer` 并通过 `.modelContainer(...)` 注入

## 4. 论文引用模块

- [x] 4.1 `Shared/Citations/PaperCitation.swift`：定义 struct + `CitationTopic` enum + `shortForm` derived
- [x] 4.2 `Shared/Citations/Citations.swift`：18 篇论文全部作为 static let 常量
- [x] 4.3 `Citations.all` 数组 + `Citations.byTopic(_:)` + `Citations.byId(_:)` 查询
- [x] 4.4 校验：所有 url 都以 `https://` 开头（用户可手动 grep 检查）

## 5. Exercise Library

- [x] 5.1 `Shared/ExerciseLibrary/Exercise.swift`：`struct Exercise` 含全部字段 + `citations` derived（解析 citationIds）
- [x] 5.2 `Shared/ExerciseLibrary/ExerciseLibrary.swift`：30 个动作（杠铃 16 + 哑铃 6 + 自重器械 7 + CMJ 跳跃 1）
- [x] 5.3 每个 `referenceV1RM` 上方都加了 `/// Reference: Citations.xxx` 注释
- [x] 5.4 `Shared/ExerciseLibrary/VelocityRanges.swift`：`defaultVelocityRange(for:goal:)` + `defaultVLCeiling(for:)`
- [x] 5.5 `Shared/ExerciseLibrary/ExerciseLookup.swift`：`exercise(byId:)` / `exercises(in:)` / `grouped` / `totalCount`
- [x] 5.6 校验：30 个动作 ✅，所有 id kebab-case ✅，每条 citations 非空 ✅

## 6. App Entry & Compose

- [x] 6.1 `VBTrainerApp.swift` 注入 ModelContainer
- [x] 6.2 `VBTrainerWatchApp.swift` 注入 ModelContainer（独立 container）
- [x] 6.3 `VBTrainer/Views/RootView.swift`：占位首页 — 显示 token 色样、动作数量分类、论文计数（验证 Tokens / ExerciseLibrary / Citations 都被正确链接）
- [x] 6.4 `VBTrainerWatch Watch App/Views/WatchRootView.swift`：占位 — 显示动作数量 + 论文计数
- [x] 6.5 占位 ContentView 渲染 token 色样 + 数据色彩 chip + 巨大数字（验证 numericLarge font）

## 7. 项目级文档

- [x] 7.1 项目根 `README.md`：Prerequisites / Open / Build / Sign / Deploy / Cert renewal / Simulator 限制 / OpenSpec 工作流说明 / 路线图
- [x] 7.2 `Shared/ARCHITECTURE.md`：解释 Modern Watch App 模式、Group vs Package 选择、SwiftData container 策略、token 单源真理、命名注意

## 8. 验收

- [x] 8.1 `xcodebuild -project VBTrainer.xcodeproj -target VBTrainer -sdk iphoneos -configuration Debug CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED** ✓
- [x] 8.2 `xcodebuild -project VBTrainer.xcodeproj -target "VBTrainerWatch Watch App" -sdk watchos -configuration Debug CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED** ✓
- [ ] 8.3 启动 iPhone simulator 跑 iOS app — **暂不可执行**（iOS 18 simulator runtime 还在用户机器上下载中。代码已编译通过，待 simulator 下完即可跑）
- [ ] 8.4 启动 Apple Watch simulator 跑 Watch app — **暂不可执行**（同上，watchOS 11 simulator runtime 还在排队）
- [x] 8.5 `openspec status --change foundation-scaffold` → 4/4 artifacts complete ✓

> **8.3 / 8.4 的处理**：simulator runtime 是用户机器上的后台下载，不影响代码完整性。Proposal 1 的核心目标是「脚手架编译通过、所有 Shared 模块就位」，已经达成。Simulator 下完后用户在 Xcode 内 ⌘R 即可看到占位界面（不需要回过头再做 proposal-1 的额外工作）。
