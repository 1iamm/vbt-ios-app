# Proposal: Foundation Scaffold

## Why

VBTrainer 项目从零开始。需要先建立 Xcode 工程脚手架（iOS + watchOS 双 target）、统一的设计系统（颜色 / 字体 / 间距 token，从 Claude Design 设计稿提取）、以及全部 SwiftData 数据模型，否则后续所有功能（采集、复盘、计划、HealthKit 集成）都无处落脚。

这是 V1 的第 0 步，**不实现任何业务功能**，只搭建结构。后续每个 OpenSpec change 都建立在本 change 之上。

## What Changes

- **新建** Xcode 项目 `VBTrainer.xcodeproj`，含两个 target：
  - `VBTrainer-iOS`（iPhone App，iOS 16+）
  - `VBTrainerWatch Watch App`（Apple Watch App，watchOS 9+）
- **新建** Bundle ID：`com.vbtrainer.app`（iPhone）+ `com.vbtrainer.app.watchkitapp`（Watch）
- **新建** Info.plist 权限声明：
  - `NSMotionUsageDescription`（IMU 采集）
  - `NSHealthShareUsageDescription`（读心率/睡眠/HRV/温度）
  - `NSHealthUpdateUsageDescription`（写训练数据）
- **新建** 设计系统 Swift 包（颜色 / 字体 / 间距 / 圆角），从 `design/iphone/.../vbt-tokens.jsx` 提取
- **新建** 全部 SwiftData @Model 类：
  - `UserProfile`（个人画像）
  - `Workout`（一次训练）
  - `ExerciseSet`（一组）
  - `Rep`（单 rep）
  - `JumpTest`（CMJ 测试，独立模型）
  - `ReadinessSnapshot`（每日身体准备度）
  - `Template`（用户自建训练计划）
  - `TemplateItem`（计划单项）
  - `PersonalRecord`（PR）
- **新建** Exercise 元数据库（30 个动作，含论文 V1RM / 默认 VL 阈值 / 测速变量 / 默认目标速度区间）
- **新建** 30 个动作的 SF Symbol 图标映射
- **新建** 论文引用清单（Swift 文件，每个算法注释里 cite）
- **新建** 项目级 README + 开发指南（如何打开、签名、真机部署）

不引入业务逻辑，不写 UI（除空 App entry），不写算法。

## Capabilities

### New Capabilities

- `project-foundation`: Xcode 项目结构、双 target 配置、Info.plist 权限、Bundle ID、签名说明
- `design-system`: 设计 token 的 Swift 表达（Theme/Colors/Typography/Spacing/Radius），浅深色主题切换
- `data-models`: SwiftData @Model 类全集 + 模型间关系 + 迁移策略
- `exercise-library`: 30 个动作元数据（V1RM / 默认 VL / 测速变量 / 默认速度区间 / 单边标记）
- `paper-citations`: 算法论文引用机制（每个论文一个常量，算法代码注释引用）

### Modified Capabilities

（无 — 这是首个 change）

## Impact

- **代码**：新建 `VBTrainer/` 项目根、所有 Swift 源文件、Info.plist、Assets.xcassets
- **依赖**：纯 Apple SDK，**零第三方**（SwiftData / SwiftUI / HealthKit / Charts / CoreMotion / WatchConnectivity）
- **签名**：使用用户个人 Apple ID 自动签名（Personal Team），仅自用真机部署有效（7 天证书）
- **后续 change 的依赖**：所有后续 change 都依赖本 change 的数据模型和设计系统
