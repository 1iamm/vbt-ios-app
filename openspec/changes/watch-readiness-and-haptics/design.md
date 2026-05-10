# Design

## 设计来源

两个 PM agent（交互 / 系统）3 轮讨论后的最终共识——分歧 6 项全部锁定。

## 决定

### Readiness 布局

| 决定 | 值 | 替代方案被否的原因 |
|---|---|---|
| 圆环外径 | **110pt 固定** | 96pt 中心 28pt 数字读不出；dynamic（40mm 104 / 45mm 116）多一个分支不值 8pt 收益 |
| 顶部 Spacer | **12pt** | 8pt 太挤会撞 status bar；26pt 是溢出元凶之一 |
| 圆环内中心数字 | **28pt SF Rounded Bold**（原 48pt） | 110pt 圆环里 28pt 是辨识度下限；48pt 在 110 圆环里会撞边 |
| Tier 文字 | **11pt** 不变 | |
| miniStat 字号 | 14pt → **12pt**，间距压到 6pt | 让 3 列在 162pt 宽 40mm 表盘也不挤 |
| 「跳过」 | **圆环下方 13pt 灰色 text link**，role `.cancel` | watchOS NavigationStack `.toolbar` 命中区 ≤24pt 比胶囊还难点；放底部并排会跟主 CTA 抢视觉 |
| 「CMJ 测试」 | **底部全宽 borderedProminent 胶囊**，accent 底色 | 这是页面唯一正向主操作 |
| 容器 | **ScrollView**（content 自然高度） | 40mm 正好填满不滚；Dynamic Type XXL / 49mm 表盘优雅滚动兜底；watchOS HIG 推荐默认容器 |

### 触觉反馈

#### MetStatus → WKHapticType 4 档映射

| MetStatus | 现状 | 决定 | 用户感知 |
|---|---|---|---|
| excellent | `.success` | **`.success`**（不变） | 上升脉冲，"漂亮" |
| met | `.click` | **`.directionUp`** | 单脉冲上扬，"达标向上" |
| borderline | `.directionUp` | **`.directionDown`** | 双脉冲下沉，"速度在掉" |
| failed | `.failure` | **`.failure`**（不变） | 强双脉冲，"该停了" |

borderline 修复的是**反向**错误——原代码 `.directionUp` 把"接近未达标"映射成了
"上扬"，与用户身体直觉相反。

#### 训练阶段震动

| 时机 | WKHapticType | 调用点 |
|---|---|---|
| 单 Rep 完成 | 上表 4 档 | `LiveWorkoutController.apply(.repCompleted)` |
| 单组结束 | `.stop` | `LiveWorkoutController.endSet()` |
| 整次训练完成 | `.success`（**单次**） | `LiveWorkoutController.completeWithFeedback()` |
| 休息倒计时归零 | `.start` | 已有，不动 |
| VL 突破 ceiling | `.failure` | 已有，不动 |
| PR 庆祝屏 | `.notification` | 已有，不动 |
| CMJ Go 弹出 | `.notification` | 已有，不动 |

**为什么训练完成是 `.success` 单次而非双发**：watchOS `WKInterfaceDevice.play()`
在 200ms 内连续调用，系统硬限会丢第 2、3 次（Apple Developer Forum 多人复现）；
单次 `.success` 比"听起来庆祝但实际丢帧"更可控。庆祝感由 UI 承担：PR 屏 + Summary
页大数字 + 数字表冠 Taptic 滚动。

### 节流

- `HapticFeedback` 内部维护 `private static var lastFireAt: Date?`
- 任何 `play()` 前检查距离上次 fire ≥ **180ms**，否则直接 drop
- 韦伯定律下界 ~200ms：两次震动相隔 < 180ms 人手腕物理上无法分辨
- 把"系统随机丢"变成"我们可控丢"
- 仅作用于 `rep(_)` 这种高频调用；`setEnded` / `workoutEnded` 之间不会触发节流

### Preference 同步（iPhone → Watch）

iPhone `UserProfile.vibrationEnabled` 开关从 V1 起就存在但**从未连通 watch**——
toggle 当下是死代码。本 change 接通：

1. **新增 message kind**：`Shared/Services/ConnectivityProtocol.swift`
   - `public struct WatchPreferencesSnapshot: Codable, Sendable, Equatable { public var enableRepHaptic: Bool }`
   - `case preferences(WatchPreferencesSnapshot)` 加入 `ConnectivityMessage` 枚举
2. **iPhone 侧**：`SettingsView` toggle 变化 → 立即 `WatchConnectivityService.shared.send(.preferences(...))`
3. **Watch 侧**：`WatchConnectivityService.session(_:didReceiveUserInfo:)` 的
   switch 加 case，写入 `UserDefaults.standard.set(snap.enableRepHaptic, forKey: "watch.enableRepHaptic")`
4. **HapticFeedback.rep(_)**：调用前读 `UserDefaults.standard.object(forKey:) ?? true`
   （首启时 key 不存在默认 ON）；为 false 时 no-op
5. `setEnded` / `workoutEnded` 不受这个开关控制（语义不同：rep 反馈是高频，
   set/workout 是阶段标记，关掉这两个会让用户以为"训练没结束"）

### 调用点位（不在 View 触发）

全部 haptic 在 `LiveWorkoutController` 触发，**不**在 SwiftUI View 的
onChange / onAppear。原因：
- View 在后台 / 锁屏 / Dock 不可见时不会运行 SwiftUI 更新循环
- Controller 是业务真相源，事件流不依赖渲染
- HKWorkoutSession 期间手腕放下，controller 仍消费 actor 事件流并触发震动

## 不做

- 不加第二个"训练完成震动"开关——`enableRepHaptic` 一个就够；训练结束震动是系统
  级反馈，应当与"操作系统语义"对齐（`.stop` / `.success`），用户不该有需要关掉的理由
- 不动 CMJ 流程震动（已就位）
- 不动 PR 庆祝、VL ceiling、休息结束震动（已就位）
- 不引入 CHHaptic 自定义波形（watchOS 不支持）
- 不为 watchOS 加独立 Settings 屏只为暴露这个开关（V1 单一开关就走 iPhone Profile）

## 风险与回退

- **风险 1**：用户测试时仍听不到训练结束震动 → 加 Logger 在
  `LiveWorkoutController.completeWithFeedback` 末尾打点；通过 Console.app 看 Watch
  日志确认 `play(.success)` 被调用过
- **风险 2**：`UserDefaults` 读取在 actor 上下文不安全 → 全部 haptic 调用都在
  `LiveWorkoutController` `@MainActor` 上下文中触发，UserDefaults 在 main 线程访问
  是 thread-safe 的
- **回退**：单 commit 即可全部 revert；触觉合约不依赖任何持久化，关掉就回到 V1 之前
