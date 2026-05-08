# VBTrainer · Shared 架构说明

## 为什么用 `Shared/` Group 而不是 Swift Package

V1 选择把所有共享代码放在一个 `Shared/` 文件夹，并通过 XcodeGen 让两个 target 都引用，**而不是**抽成 Swift Package。

理由：
- V1 项目规模小（< 50 个 Swift 文件），Package 仪式收益小
- 用户是后端工程师，第一次接触 Xcode，Group 模式比 Package 更直观
- SwiftData `@Model` 在 Package 模块化时有些坑（macro 跨 module 行为）
- V2 项目规模扩大、加私教 SaaS 后端时再抽 Package

## 共享了什么

```
Shared/
├── Models/              # @Model 全集 + Enum 定义 + ModelSchema
├── Theme/               # Tokens（颜色/字体/间距/圆角）
├── ExerciseLibrary/     # 30 个动作元数据 + Lookup helpers
├── Citations/           # 论文引用结构 + 18 篇论文常量
└── Extensions/          # Color(hex:) 等小工具
```

不共享的：
- iOS 端 `Views/` `Services/`
- watchOS 端 `Views/` `Sensors/` `Algorithms/`（算法可能 watchOS-only）

## SwiftData ModelContainer 策略

每个 target 各自创建一个 `ModelContainer`，对应同一个 Schema (`VBTSchemaV1.allModels`)。Watch 和 iPhone 各持有一份本地数据，通过 WatchConnectivity（Proposal 4）做单向数据流：

```
Watch 训练采集 ──[训练结束批量传]──▶ iPhone 主库
iPhone 计划编辑 ──[即时下发]──▶ Watch 缓存
```

**不**做实时双向同步（电量考虑）。

## Token 单源真理

`Shared/Theme/Tokens.swift` 是 Swift 表达，但不是 token 的真源——真源是
`design/iphone/vbt-iphone/project/vbt-tokens.jsx`（Claude Design 输出）。

任何修改：
1. 先改 `vbt-tokens.jsx`
2. 同步改 `Tokens.swift`
3. 提交时两个文件一起提

如果两边漂移，以 `vbt-tokens.jsx` 为准。

## 论文引用约定

每个从论文推导出来的常量（V1RM、VL 阈值、HRmax 公式、等等）必须在赋值前 5 行内写：

```swift
/// Reference: Citations.gonzalezBadillo2010Velocity (bench MPV ≈ 0.17 m/s @ 1RM)
let benchV1RM: Double = 0.17
```

这个约定让 `grep referenceV1RM` 或者 `grep "let.*V1RM"` 能立刻看到出处。

## 命名注意

- **`WorkoutSet`**（不是 `ExerciseSet`）——避免和 Swift 的 `Set` 集合类型冲突，否则 SwiftUI Preview 和 IDE 经常混淆
- **`exerciseLibrary`**（小写复数）——是 `[Exercise]` 数组常量，不是单数模型
- 所有 Exercise.id 用 kebab-case（`back-squat`），不用 camelCase
