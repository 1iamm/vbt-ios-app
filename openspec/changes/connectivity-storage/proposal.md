# Proposal: Connectivity & Storage

## Why

Proposal 2 输出 `WorkoutSnapshot`（值类型），但目前只在内存中。本 proposal 把它持久化到 SwiftData，并通过 WatchConnectivity 把训练完成的数据从 Watch 传到 iPhone，构成"采集→存储→展示"的真实链路。

## What Changes

- 新建 `Shared/Services/WorkoutStore.swift`：`WorkoutSnapshot` ↔ SwiftData `Workout` 双向转换
- 新建 `Shared/Services/ConnectivityProtocol.swift`：双端共享的 message 协议（snapshot, plan-template）
- 新建 `VBTrainerWatch Watch App/Services/WatchConnectivityService.swift`：WCSession Watch 端封装，负责发送 snapshot
- 新建 `VBTrainer/Services/iPhoneConnectivityService.swift`：WCSession iPhone 端，接收 snapshot 并写入 SwiftData
- 新建 `Shared/Services/JumpTestStore.swift` / `Shared/Services/ReadinessStore.swift`：CMJ 和 Readiness 的本地 CRUD
- 修改两端 App entry：注入 ConnectivityService

## Capabilities

### New Capabilities

- `workout-storage`: WorkoutSnapshot ↔ SwiftData 持久化
- `watch-connectivity`: 双端 WCSession + 消息协议
- `jump-test-storage`: CMJ 测试持久化
- `readiness-storage`: 每日 readiness 持久化

## Impact

- Watch 端训练结束自动触发批量传（不实时）
- iPhone 端在前后台都能收（用 transferUserInfo）
- 数据全部本地，零服务器
