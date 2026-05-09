## Context

V1 Phase 0 完成后底层算法 / actor / 通信全就位，但实时训练 UI 是占位（`WatchScreens.swift` 里的 `@State private var rep: Int = 5` 等硬编码）。真机一跑发现链路完全没接通。本 change 是"补线"，最小代价让 Watch 能采到真实数据并把结果送回 iPhone。

## Goals / Non-Goals

**Goals:**
- 用户进 Live Workout 屏，UI 上的 rep / velocity / vlPercent / heartRate / metStatus 都来自真实传感器
- "结束本组" → `session.endSet()` → 进 Rest 倒计时
- "完成" → `session.complete()` → `WatchConnectivityService.send(.workoutSnapshot(snap))` → iPhone 端 `WorkoutStore.save` 落库
- HKWorkoutSession 真能在真机上跑起来（授权 + 后台模式齐全）
- 不引入新算法、不改 actor 公共 API、不动同步协议

**Non-Goals:**
- 不接 onboarding 选择的 Tweaks（target velocity / vlCeiling 等都先用 nil/默认）
- 不改 plan-execution-sync 流程（plan 入口走另一条路径，本次不动）
- 不在 Watch 端做 SwiftData 持久化（V1 设计：Watch 内存 → 通过 WCSession 给 iPhone 落库）
- 不做错误 UI（这次只加 Logger，让真机出问题时能定位；正式错误屏 UI 后续 polish）
- 不改 Rest / Summary 视觉设计

## Decisions

### D1: 用 `LiveWorkoutController: @MainActor ObservableObject` 桥接 actor

**问题**：`ActiveWorkoutSession` 是 `actor`，SwiftUI 不能直接 bind actor 上的属性。事件流是 `AsyncStream<SessionEvent>`，需要消费。

**方案**：新建 `LiveWorkoutController`（`@MainActor final class`），内部持 `ActiveWorkoutSession`，在 `start()` 里 `Task { for await event in await session.events { ... } }` 把事件映射到 `@Published var rep / velocity / vlPercent / heartRate / metStatus / lastSetSnapshot / completedSets`。SwiftUI View 持 `@StateObject var controller`，直接读 `@Published`。

**为什么不用 `@Observable` 宏**：当前代码全用 `ObservableObject`（如 `WatchNavigation`），保持一致。

**为什么 controller 在 View 层而非 App 层**：训练 session 生命周期 = LiveWorkoutView 生命周期；放 App 层会泄露到其他屏。

### D2: Controller 在 View 层之间共享：用 environment object

**问题**：LiveWorkoutView → RestView → SummaryView 是 nav stack 推进，每个屏都是独立 View，但需要共享同一个 controller。

**方案**：`WatchLiveWorkoutView.body` 用 `.environmentObject(controller)` 注入到 children；Rest / Summary 用 `@EnvironmentObject var controller: LiveWorkoutController` 读取。

替代方案（被否）：把 controller 提到 `WatchRootView` / `WatchNavigation`。否决理由是 controller 的生命周期严格绑定到一次训练，提到 root 会让其他屏（如 readiness、CMJ）也意外持有。

### D3: HealthKit 授权时机：app 启动一次性请求

**问题**：`HKWorkoutSession` 创建需要至少 share `HKObjectType.workoutType()`，心率读取需要 `.heartRate`。

**方案**：`VBTrainerWatchApp.init` 里 `Task { try? await HealthKitAuthorization.requestWorkoutAuthorization() }`。

请求集合：
- typesToShare: `HKObjectType.workoutType()`、`HKQuantityType(.activeEnergyBurned)`
- typesToRead: `HKQuantityType(.heartRate)`、`HKQuantityType(.activeEnergyBurned)`、`HKObjectType.workoutType()`

**为什么不在 MotionManager 内部按需请求**：MotionManager 是 actor，多次调 `requestAuthorization` 系统不会再弹弹窗（已授权直接返回），但首次调用通常发生在用户已经按了 "开始训练" 按钮 → 弹窗体验突兀。提前到 app 启动更顺。

### D4: 完成训练后立即发 WCSession，不等用户按 "完成"

**否决**：在 `session.complete()` 里直接 send。

**采用**：`WatchSummaryView` 的 "完成" 按钮触发 `controller.complete()` → 拿到 snapshot → 调 `WatchConnectivityService.shared.send(.workoutSnapshot(snap))` → `nav.popToRoot()`。

理由：
- 用户可能在 Summary 屏看完后想做修改 / 加备注（V2 功能）
- `transferUserInfo` 是 best-effort，不阻塞 UI
- 失败处理简单：log + 下次启动时检查未发送队列（V1.5 云同步会做，V1 接受丢失风险）

### D5: 防御性 cancel：onDisappear 强制释放传感器

**问题**：用户在 Live Workout 屏长按 Digital Crown → Watch 强制 pop 出 stack，session 不会自动结束 → MotionManager 还在采样，HKWorkoutSession 还活着，电量泄漏。

**方案**：`WatchLiveWorkoutView.onDisappear` 调 `controller.cancel()`，内部判断如果 state ≠ `.completed` 则调 `session.complete()` 并 discard 结果（actor 的 `complete()` 已经会 stopSensors / cancelRest）。

但要避免误触发：从 LiveWorkout push 到 Rest 时 LiveWorkout 也会 disappear（NavigationStack 行为）。解决：用 `nav.path.count` 判断是否 pop 到 root。更简单：用 `@State var didTransition = false`，按"结束本组"或"完成"前置 true，`onDisappear` 只在 didTransition == false 时 cancel。

### D6: 单元测试范围

本 change **不写单测**。理由：
- `LiveWorkoutController` 依赖 `ActiveWorkoutSession`（watchOS-only actor，进而依赖 `MotionManager` / `HKWorkoutSession`），iOS Tests bundle 不能 import
- 把 `SessionEvent` enum 提到 Shared 以便测试，会引入跨平台抽象（protocol SessionEventSource），范围扩散
- CLAUDE.md 约定 "算法写单测，UI 不写"；controller 是 UI 桥接，逻辑是 switch event → 字段赋值，bug 风险低
- 真机验证（§Verification）足以覆盖端到端

如未来需要单测，最小重构：把 `SessionEvent` 提到 `Shared/Algorithms/`，controller 接 protocol，注入 mock。

## Risks / Trade-offs

- **Risk**: HealthKit 授权弹窗体验不好（app 第一次打开就弹） → **Mitigation**: 写明"VBTrainer 需要使用心率与训练 session"的 usage description（已在 project.yml）
- **Risk**: 用户拒绝授权 → MotionManager.start() 抛错 → **Mitigation**: controller.start() 捕获错误 → @Published 暴露 errorMessage → UI 显示"请到设置里授权"，不崩
- **Risk**: actor → MainActor 桥接 Task 泄漏 → **Mitigation**: controller 持 `private var consumerTask: Task<Void, Never>?`，`cancel()` / `deinit` 显式 cancel
- **Trade-off**: 用 `@StateObject` controller 而非把状态直接放 ActiveWorkoutSession actor → 一份数据两处维护（controller 的 @Published 字段是 actor 状态的镜像）。可接受，因为 SwiftUI bind actor 的官方推荐路径就是这个

## Migration Plan

无（首次接通，无既有数据 / API 变更）。

## Open Questions

- **Plan execution 入口**：从 today plan 进入训练时，是否也走同一个 LiveWorkoutView？目前看 WatchRoute 只有一个 `.liveWorkout`，应该是统一的。如果不是，下一个 change（plan-execution-watch-wire）再处理。
- **VL 警戒线触发后的 UI**：当前 `vlStopWarning` route 已有，但需要 controller 监听 `.vlCeilingExceeded` 事件后触发 `nav.push(.vlStopWarning(...))`。本 change 不做（onboarding 没接，vlCeiling 默认 nil 不会触发）；待 Tweaks 接入时一起补。
