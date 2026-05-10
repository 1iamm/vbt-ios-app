# watch-haptics

## Purpose

Live Workout 全流程的触觉反馈合约：用户在不看屏幕（深蹲离心、卧推过顶）的瞬间能
通过手腕震动感知 Rep 速度档位、单组结束、整次训练完成。

## Requirements

### Rep haptic mapping

- Rep 完成时 SHALL 根据 `MetStatus` 触发以下 `WKHapticType`：
  - `.excellent` → `.success`
  - `.met` → `.directionUp`
  - `.borderline` → `.directionDown`
  - `.failed` → `.failure`

### Stage haptics

- 单组结束（`endSet()`）SHALL 触发 `.stop`
- 整次训练完成（`complete()` / `completeWithFeedback()`）SHALL 触发 `.success`
  **单次**（不可双发——watchOS 200ms 内连续 play 系统硬限丢帧）

### Throttling

- 任意 haptic 调用 SHALL 检查距离上次 fire 时间
- 间隔 < 180ms 时 SHALL drop 当前调用（不入队、不延迟、不缓冲）
- 节流仅作用于 Rep 完成 haptic；阶段震动（setEnded / workoutEnded）之间互不节流

### Source of truth

- 所有 Live Workout 期间的 haptic SHALL 在 `LiveWorkoutController` 内触发
- Haptic SHALL NOT 由 SwiftUI View 的 `.onChange` / `.onAppear` 触发
- 原因：View 在后台 / 锁屏不运行更新循环；controller 是事件真相源

### Preference gating

- iPhone `UserProfile.vibrationEnabled` 变化时 SHALL 通过
  `ConnectivityMessage.preferences(WatchPreferencesSnapshot)` 同步到 watch
- Watch SHALL 缓存 `enableRepHaptic` 到 `UserDefaults.standard` key
  `"watch.enableRepHaptic"`
- key 不存在时 SHALL 默认视为 `true`（首启不能"哑巴"）
- `enableRepHaptic == false` 时 Rep haptic SHALL no-op
- `enableRepHaptic == false` 时 setEnded / workoutEnded haptic SHALL **仍触发**
  （阶段标记不应被关闭）

## Behaviour

#### Scenario: Rep 速度达到目标区间
- **WHEN** `MetStatus = .met`
- **THEN** 触发 `.directionUp`（不再是历史的 `.click`）

#### Scenario: 连续两次 Rep 间隔 < 180ms
- **WHEN** 第二次 Rep 在第一次震动后 100ms 触发
- **THEN** 第二次震动被 drop，用户感受到一次震动

#### Scenario: 用户在 iPhone 关掉 Rep 震动
- **WHEN** Profile.vibrationEnabled 从 true 改为 false
- **THEN** iPhone 立即 `send(.preferences(.init(enableRepHaptic: false)))`
- **AND** Watch 收到后写入 UserDefaults
- **AND** 后续 Rep 不再震动，但单组结束 / 训练完成仍震动

#### Scenario: 单组结束
- **WHEN** Watch 用户点「结束本组」
- **THEN** `.stop` 触发一次，区别于 Rep 震动

#### Scenario: 整次训练完成
- **WHEN** Watch 用户点 Summary 「完成」
- **THEN** `.success` 触发一次，且在 `WatchConnectivityService.send` 之前播放
  （否则锁屏可能延迟反馈）
