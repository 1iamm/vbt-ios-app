# Design

## 决定

### VL 触发：通过通知而非直接 push

`LiveWorkoutController` 是 `@MainActor ObservableObject`，没有 navigation 引用。
让它直接 push 路由会让 controller 与 navigation 耦合。沿用 commit 2 的
WatchActivationCenter 模式：post 通知 + WatchRootView 监听。

### 通知 payload

```swift
let info: [String: Any] = ["vl": vl, "threshold": threshold]
NotificationCenter.default.post(name: .vbtVLCeilingExceeded, object: nil, userInfo: info)
```

WatchRootView：
```swift
.onReceive(NotificationCenter.default.publisher(for: .vbtVLCeilingExceeded)) { note in
    let vl = note.userInfo?["vl"] as? Double ?? 0
    let th = note.userInfo?["threshold"] as? Double ?? 0
    nav.push(.vlStopWarning(vl: vl, threshold: th))
}
```

### Side chip 设计

| Side | UI |
|---|---|
| `.both` | 不显示 chip |
| `.left` | 11pt 蓝色 chip「左侧」 |
| `.right` | 11pt 蓝色 chip「右侧」 |

放在 SetReady 动作名右侧（小尺寸不抢主视觉）。

### 删除清单

| 删 | 理由 |
|---|---|
| `WatchHomeView` | V2 用 SyncIdleView 作 root，不再有 launcher |
| `WatchExercisePickerView` | 用户决定彻底删除 watch 选动作能力 |
| `WatchWeightInputView` | 同上 |
| `WatchCMJCountdownView/GoView/ResultView` | 用户决定 CMJ 全部移到 iPhone；watch 三屏未来另开 change 重做 |
| `WatchPlanProgressView` / `WatchPlanNextView` | 已被 PlanSynced 取代 |
| Readiness 屏的「CMJ 测试」按钮 | V2 主流程不再触发 CMJ |

`WatchReadinessView` struct 本身**保留**——iPhone 推送 readiness 数据后 watch 仍可
显示（PR #9 刚修过布局），只删 CMJ 入口按钮。

### Route enum 同步

删：
- `case exercisePicker`
- `case weightInput(exerciseId: String)`
- `case cmjCountdown`
- `case cmjGo`
- `case cmjResult(attempts: [Double])`
- `case planProgress`
- `case planNext`

保留：
- `readiness`（iPhone 仍可推 readiness 给 watch）
- `summary`（旧 V1 RPE 输入屏的入口，commit 4 暂留——RPE/Feeling 主观评价是不同维度）
- `prCelebration / vlStopWarning / rpeInput`（事件型路由，保留）
- 5 个 V2 case 全保留

`WatchRootView.routeView(_:)` 的 switch 同步删除分支。

### 兼容外部调用站

旧 V1 路由的 push 调用站：
- `nav.push(.exercisePicker)` —— commit 1 已替换 / 此 commit 再扫一遍
- `nav.push(.weightInput(...))` —— 同上
- `nav.push(.summary)` —— 保留，因为 summary case 不删

因此本 commit 删 case 时只需确认无残留 push 调用即可。

## 不做

- 不动 V2 主流程视觉（commit 3 已做）
- 不改算法、连接协议
- 不实装 iPhone-driven CMJ 链路（未来另开 change）
- 不删 PR celebration 的触发逻辑（设计稿没画但保留为 dead route，未来云同步阶段再启用）

## 风险与回退

- **风险**：删 7 个 view struct 后某处遗留引用 → 编译失败。`./scripts/verify.sh` 会
  立刻发现 cross-file 引用问题。先验证再 commit
- **回退**：单 commit revert 即可
