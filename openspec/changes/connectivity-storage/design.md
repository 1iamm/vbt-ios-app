## Context

Watch 训练采集结束后产出 `WorkoutSnapshot`（值类型）。要让 iPhone 端能复盘，必须：(a) 持久化 (b) 跨设备传输。WatchConnectivity 是唯一可行的双端通信方式。

## Goals / Non-Goals

**Goals:**
- WorkoutSnapshot ↔ SwiftData Workout 完整双向映射（含 sets/reps/heartRate）
- 训练结束 → Watch 端持久化本地一份 + 调 transferUserInfo 发到 iPhone
- iPhone 后台收到 → 写入主库 → 通过 NotificationCenter 通知 UI 刷新

**Non-Goals:**
- 不做实时双向同步（只在训练结束时 push）
- 不做计划模板的双端同步（Proposal 9）
- 不做 HealthKit 写回（Proposal 7）

## Decisions

### D1: 传输方式 — transferUserInfo 而非 sendMessage

`transferUserInfo` 在双端都不在前台时也能传（系统调度），适合训练结束时 Watch 上 App 立即关闭、用户拿起手机时收到的场景。`sendMessage` 要求双端 reachable，会失败。

### D2: 消息序列化 — JSON via Codable

`WorkoutSnapshot` 已经 `Codable`，序列化为 `Data`，放入 userInfo 字典 `["snapshot": <data>, "kind": "workout"]`。

### D3: 双端 SwiftData container

各自独立 container；通过 connectivity 同步数据；不共享文件（App Group 在免费证书限制下不靠谱）。

### D4: 重复消息去重

iPhone 收到 snapshot 时按 `id: UUID` 检查是否已存在，存在则跳过（防止 transferUserInfo 重发）。

## Risks / Trade-offs

- WCSession 在 simulator 不工作（需要真机配对）— V1 用真机测，simulator 跳过
- transferUserInfo 队列上限 ~65535 字节 — 长 workout 心率序列可能超限；用 Codable 压缩 + 必要时分片
