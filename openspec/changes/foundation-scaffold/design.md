> ⚠️ **历史文档说明（2026-05-08 修订）**
> 本 change 是 V1 起步时的设计文档，部分内容在实施过程中或之后修订：
> - **部署目标**：原计划 iOS 16 / watchOS 9，**实施时改为 iOS 17 / watchOS 10**（SwiftData @Model 强制要求）。tasks.md 1.3 已记录修订
> - **类名**：原计划 `ExerciseSet`，实施时改为 `WorkoutSet`（避开 Swift `Set` 类型冲突）
> - **数据策略**：原 V1 决定"数据全本地，不传服务器"，**V1.5 起改为 Hybrid Local-First + Opt-in Cloud Sync**（详见 [docs/CLOUD_ARCHITECTURE.md](../../../docs/CLOUD_ARCHITECTURE.md)）
> - **下方原文保留作为决策审计追踪，不再代表当前架构**

---

## Context

VBTrainer 项目从空仓库起步。已有：
- `PRD.md`：完整 V1 产品规格
- `design/iphone/...` + `design/watch/...`：Claude Design 导出的 HTML/JSX 设计稿（含 `vbt-tokens.jsx` 设计系统）
- 用户使用 macOS 15.3 + Xcode 16.0
- 个人 Apple ID（美区），暂用免费个人证书

约束：
- 必须 watchOS 9+ / iOS 16+ 起支持（PRD 决策）
- 中文 UI（V1），但代码用 `String(localized:)` 包好，i18n-ready
- 零第三方依赖（Apple SDK only）
- 数据全本地（SwiftData + HealthKit），不传服务器

## Goals / Non-Goals

**Goals:**
- 一键 `open VBTrainer.xcodeproj` 即可在 Xcode 打开并构建（即使 simulator 没下完）
- 设计 token 与 `vbt-tokens.jsx` 数值精确对应（颜色 hex 一致、间距 4pt 制对齐）
- SwiftData 模型覆盖 PRD 全部数据流（训练 / 计划 / 准备度 / CMJ / PR / 用户画像）
- 30 个动作元数据完整（V1RM、默认 VL、测速变量、目标速度区间），每条标注论文出处
- 论文引用机制：每个算法相关常量都关联到论文 DOI（编译期常量，运行时可查）

**Non-Goals:**
- 不实现传感器采集（Proposal 2）
- 不实现 UI（Proposal 3+）
- 不实现 HealthKit（Proposal 7）
- 不做 V2 的 AI / 云同步 / Keep导入

## Decisions

### D1: Xcode 项目结构 — 单 .xcodeproj 双 target

选 **单工程双 target**（iOS 主 + watchOS 嵌入），不选 Workspace + 多工程。

理由：
- watchOS App 必须以 iOS App 的"延伸"形式存在（Companion App 模式）
- Xcode 14+ 推荐用 **Modern Watch App**（独立 watchOS Target，Watch 不再嵌入 iOS bundle）— 这是我们的选择
- 单 .xcodeproj 让所有共享代码（Models / Theme / ExerciseLibrary）通过 Group 引用即可，不需要单独 Swift Package

### D2: 共享代码组织 — Group 而非 Swift Package

V1 不引入 Swift Package。共享 Swift 文件（Models、Theme、ExerciseLibrary、PaperCitations）放在 `VBTrainer/Shared/` 目录，**两个 target 都加入 membership**。

理由：
- V1 项目规模小，Package 收益小成本高
- 用户是后端工程师，第一次接触 Xcode，Group 模式比 Package 更直观
- V2 规模大了再抽 Package

### D3: 设计 Token 表达 — Swift enum + Color extension

```swift
enum Tokens {
    enum Color { static let accent = Color(hex: "FF9500") }
    enum Space { static let xs: CGFloat = 4; ... }
    enum Radius { static let card: CGFloat = 14; ... }
    enum Font { static let display = Font.system(...); ... }
}
```

理由：
- 编译期常量，零运行时开销
- 命名空间清晰（`Tokens.Color.accent`）
- 浅色/深色由 SwiftUI `@Environment(\.colorScheme)` 自动切换 + Asset catalog Light/Dark variant
- 数据可视化色（hr/vel/vol/vl/slp）单独命名空间 `Tokens.Color.Data`

### D4: SwiftData 模型策略 — 单一 Schema，单 ModelContainer

所有 @Model 类放在 `Models/` 目录。一个 `VBTrainerModelContainer` actor 全局单例，watchOS 和 iOS 各自一份（不共享，通过 WatchConnectivity 同步）。

理由：
- SwiftData 简化了 Core Data 仪式
- 关系建模：Workout → [ExerciseSet] → [Rep] 用 `@Relationship(.cascade)`
- 模型迁移：V1 用 `Schema(versionedSchema:)` 留 V2 升级位

### D5: Exercise 元数据 — 编译期 struct 数组

不用 JSON 文件，直接 Swift `let exerciseLibrary: [Exercise] = [...]`。

理由：
- 编译期检查，少一份运行时解析
- Exercise 是常量，不需要用户编辑（用户编辑的是 Template）
- 论文引用直接用 `PaperCitation.gonzalezBadillo2010` 关联

### D6: 论文引用机制 — `PaperCitation` 结构 + 全局常量

```swift
struct PaperCitation {
    let id: String          // "gonzalezBadillo2010"
    let authors: String
    let year: Int
    let title: String
    let journal: String
    let doi: String?
    let url: String
}

enum PaperCitations {
    static let gonzalezBadillo2010 = PaperCitation(...)
    // ...
}
```

每个算法常量（如 V1RM 0.30 m/s）通过 `cite: PaperCitations.gonzalezBadillo2010` 关联。设置页有"引用论文"列表，点击跳转 URL。

### D7: 颜色实现 — Asset catalog + Color(hex:) helper

- 所有数据色（accent / hr / vel / ...）注册到 `Assets.xcassets` 的 Color Set，每个有 Any/Light/Dark 变体
- 中性色（label / secondary / bg）用 SwiftUI 系统色（`Color(.label)` / `Color(.secondaryLabel)` / `Color(.systemBackground)`）
- 提供 `Color(hex: "FF9500")` 扩展用于数据色（与设计稿 hex 对应）

### D8: 国际化 — String Catalog (.xcstrings)

V1 用 Xcode 15 引入的 String Catalog（替代 Localizable.strings）。代码里写 `String(localized: "training.start")`，自动生成 catalog 条目。V1 仅中文，但结构 ready。

### D9: Bundle ID + 签名

- iOS：`com.vbtrainer.app`
- watchOS：`com.vbtrainer.app.watchkitapp`
- Team：用户的个人 Apple ID（Personal Team），自动签名
- 部署目标：iOS 16.0 / watchOS 9.0（PRD 决策，覆盖 Series 7 起）

## Risks / Trade-offs

- **风险**：watchOS Target 配置复杂（Companion ID、provisioning） → **缓解**：用 Xcode 模板 "iOS App with Watch App"，再调 Bundle ID 和 deployment target
- **风险**：用户首次开 Xcode 选 Team 报错 → **缓解**：README 写明"Signing & Capabilities → Team → 选个人 Apple ID"
- **风险**：免费证书 7 天过期 → **缓解**：README 写明重新部署流程，V1 末考虑付 ¥99/年
- **权衡**：Asset catalog 颜色定义繁琐（每个色 6 个变体） → 接受，换来系统化深浅色支持
- **权衡**：30 动作元数据写死 Swift（不易编辑） → 接受，V1 不需要用户改动作

## Migration Plan

V1 首版，无迁移。SwiftData Schema 标记版本 1，留 V2 升级位。

## Open Questions

- **iPad 适配**：V1 只 iPhone。用户用 iPad 时会模糊放大，可接受。V2 再做 iPad split view。
- **App Icon**：V1 用占位（黑底+橙色 SF Symbol "bolt.fill"），上架前换正式 icon。
- **真机测试**：CMMotion 必须真机，simulator 数据是假的。提前在 README 强调。
