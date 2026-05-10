# Design

## 决定

### 路由策略：渐进式叠加，不一刀切

| 决定 | 值 | 替代方案否决原因 |
|---|---|---|
| 旧路由（exercisePicker / weightInput / cmjCountdown / cmjGo / cmjResult / planProgress / planNext / readiness / liveWorkout / rest / summary）保留 | 全部留着 | 一刀切删会让 commit 1 涉及 800+ 行变更，不利于 review；且每个 commit 必须自洽编译 |
| 新增 5 个 V2 case 共存 | `syncIdle / planSynced / setReady / setResult / workoutDone` | 设计稿主流程必需，必须先有路由才能在 commit 3 做视觉 |
| Root view 切换 | `WatchHomeView()` → `SyncIdleView()` | 用户直观感受 V2 主流程入口已变；旧 Home 仍可通过 nav.push 访问（commit 4 删） |
| `liveWorkout` / `rest` 路由 associated values 是否在本 commit 砍 | **否**，保留 | 砍 associated values = 改 controller.start 接口 = 影响 LiveWorkoutController 多个调用方；放到 commit 3 视觉重做时一起改更内聚 |

### Stub view 规格

每个新增 view ≤ 30 行，仅含：
- `WatchScreenChrome(title: ...)` 包壳
- 一行占位文字标识屏幕名（如「SyncIdle · 等待手机」）
- 一个「下一步」按钮 push 到下一屏，让真机调试时能手动走完链路
- 不读 controller 状态、不绑数据、不做 navigation 自动推进

目的：保证在 commit 1 完成后真机能跑通 SyncIdle → PlanSynced → SetReady → LiveSet
（旧 LiveWorkout 临时占用）→ … 这条骨架路径，确认路由跳转无 bug 再做视觉。

### 与 commit 2 的边界

commit 1 **不**做：
- iPhone 推 startWorkout 信号 → 那是 commit 2 的事
- LiveWorkoutController 崩溃恢复 → commit 2
- 新增 ConnectivityMessage case → commit 2

### 与 commit 3 的边界

commit 1 **不**做：
- 任何视觉细节（字号、间距、颜色按设计稿对齐）→ commit 3
- LiveSet / Rest 改造 → commit 3
- `liveWorkout` / `rest` 路由 associated values 移除 → commit 3

## 不做

- 不删旧路由 case / 不删旧 view struct（commit 4 的事）
- 不动算法、连接协议、HapticFeedback、Tokens
- 不动 iPhone 端代码（commit 2 才动）

## 风险与回退

- **风险**：新增 5 个 case 后 routeView switch 缺失分支会 warning。已逐一加上。
- **回退**：单 commit revert 即可，无外部依赖
