# Design

## 决定

### 激活信号 vs template push 的关系

| 决定 | 值 | 替代方案否决原因 |
|---|---|---|
| 两条独立消息 | `template` + `startWorkout` | 把 startItemIndex 塞进 template 会污染纯数据 schema；旧 watch 收到混入字段会忽略而不崩 |
| 顺序 | 先 template 再 startWorkout | template 必须先到 TodayPlanStore，否则 watch 收到 startWorkout 时找不到模板；transferUserInfo 是 FIFO buffered，先发先到 |
| Watch 端响应 | NotificationCenter post → WatchRootView 监听 | 不在 ConnectivityService 直接持有 WatchNavigation 引用——actor / @MainActor 边界；通知是 watchOS 推荐的跨层异步触发方式 |

### WatchActivationCenter 设计

新文件 `VBTrainerWatch Watch App/Services/WatchActivationCenter.swift`：

```swift
@MainActor public final class WatchActivationCenter: ObservableObject {
    public static let shared = WatchActivationCenter()
    @Published public private(set) var pending: StartWorkoutSnapshot?
    public func activate(_ snap: StartWorkoutSnapshot) { pending = snap; post notification }
    public func consume() -> StartWorkoutSnapshot? { let s = pending; pending = nil; return s }
}
```

WatchRootView 通过 `.onReceive(NotificationCenter.default.publisher(for: .vbtWatchActivated))`
触发：
- `nav.popToRoot()`
- `nav.push(.planSynced)`
- 不在 commit 2 直接 push `.setReady` —— 让用户先看 PlanSynced 列表再手动开始（保留
  人在回路的确认环节，避免错按 iPhone 后 watch 直接进训练态）

### 崩溃恢复持久化

| 状态字段 | 存储位置 | 恢复时机 |
|---|---|---|
| `plannedSpecs[]` | UserDefaults JSON | watch app 启动 + WatchActivationCenter.consume |
| `plannedSetCursor` | UserDefaults Int | 同上 |
| `currentTemplateId` | UserDefaults String | 同上 |

key 前缀：`vbt.live.resume.*`。在 `LiveWorkoutController.preparePlanned(item:)` 调用
末尾 + 每次 `endSet()` 后写入；`completeWithFeedback()` 末尾清空。

V2 commit 2 仅落地接口，恢复行为的 view 联动（如「检测到上次中断的训练，是否继续？」
弹窗）放到 commit 3-4 完整闭环时再做。**本 commit 仅保证字段持久化不丢。**

### 跨版本兼容（关键）

iPhone V2 build push `.startWorkout`：
- watch V1 build（PR #9 之前）：decoder 落到 `default: break`，无副作用
- watch V2 build（commit 2 后）：handler 调用 activate

iPhone V1 build push 不发 `.startWorkout`：
- watch V2 build：等不到激活信号，留在 SyncIdle，用户手动点入。

无 schema 破坏。

## 不做

- 不改算法层、HapticFeedback、Tokens
- 不实装 WatchActivationCenter.consume 的真实业务（commit 3 的 V2 view 触发 controller.start 时再消费）
- 不在 commit 2 引入「检测到中断训练 → 弹窗继续」UI（那是 commit 3-4）
- 不动 iPhone 端「在 Watch 上开始」按钮文案（保持现状）

## 风险与回退

- **风险**：iPhone 老版本的用户升级 V2 watch 后会发 `.template` 但不发 `.startWorkout` —— 体验降级到 V1（手动从 SyncIdle 点进），不崩
- **风险**：watch 老版本（V1）用户拿到 iPhone V2 build 的 `.startWorkout` —— decoder fall through，无影响
- **回退**：单 commit revert，不影响 V1 功能；ConnectivityProtocol 加的 case 在两边 fall through 是良性的
