# watch-readiness-and-haptics

## Why

真机测试暴露两个 watchOS 体验问题：

1. **「今日准备度」页面布局溢出**：固定 130pt 圆环 + 26pt 顶部 Spacer + 三列
   miniStat + 底部按钮行，总高约 204pt；40mm 表盘可用区域仅 ~197pt。结果：
   底部「跳过」与「CMJ 测试」按钮被砍掉一半，用户无法点击。
2. **训练流程几乎无触觉反馈**：`HapticFeedback.rep(MetStatus)` 工具方法已定义
   但在 Live Workout 流程中**从未被调用**；单组结束、整次训练结束**完全无震动**。
   用户在看不到屏幕（深蹲离心、卧推过顶）时无法感知"刚才那一下速度达没达标 /
   这组结没结束"。

## What

- **Readiness 屏布局重做**：圆环 130→110pt、顶 Spacer 26→12pt、ScrollView 兜底
  Dynamic Type 大字号、「跳过」从胶囊按钮降级为圆环下方灰色 text link、
  「CMJ 测试」升为底部全宽 borderedProminent 主 CTA。
- **触觉反馈接通 Live Workout 全流程**：`LiveWorkoutController` 在
  `.repCompleted` / `endSet()` / `complete()` 三个点位触发对应震动；4 档 MetStatus
  分别映射到 `.success / .directionUp / .directionDown / .failure`；单组结束
  `.stop`、训练完成 `.success`；180ms 节流避免 watchOS 系统级丢震动；
  iPhone Profile 的 `vibrationEnabled` 开关通过新增的 `.preferences`
  ConnectivityMessage 同步到 watch 端 @AppStorage 缓存。

## Impact

- **新增 capabilities**：`watch-readiness`（屏幕布局契约）、`watch-haptics`（触觉
  反馈合约）
- **改动文件**：
  - `VBTrainerWatch Watch App/Views/WatchScreens.swift`（WatchReadinessView 重写）
  - `VBTrainerWatch Watch App/Views/HapticFeedback.swift`（新增 setEnded /
    workoutEnded、修正 rep 映射、加节流、加 enabled 开关读取）
  - `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`（接通 3 个 haptic
    call site）
  - `VBTrainerWatch Watch App/Services/WatchConnectivityService.swift`（处理
    `.preferences` 入站）
  - `VBTrainer/Services/iPhoneConnectivityService.swift` 或同等位置（Profile
    toggle 变化时 `send(.preferences(...))`）
  - `Shared/Services/ConnectivityProtocol.swift`（新增
    `WatchPreferencesSnapshot` + `.preferences` case）
- **零新依赖**、零数据迁移、watchOS 部署目标不变
