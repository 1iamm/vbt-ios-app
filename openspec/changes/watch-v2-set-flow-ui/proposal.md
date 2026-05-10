# watch-v2-set-flow-ui

## Why

Commit 1 立了路由骨架，commit 2 接通了 iPhone 激活信号。现在要把 V2 设计稿的 7 屏
视觉实现到位——这是用户最直观感知到「换了一版 App」的部分。

Commit 1 的 5 个 stub view 仅占位调试用。设计稿主张：
- **PlanSynced**：按动作分组的 Crown 滚动列表，当前组橙色高亮
- **SetReady**：动作名 28pt + 重量 39pt + 底部全宽橙色 capsule「⚡本组开始」
- **LiveSet**（替换现 WatchLiveWorkoutView）：95pt 主数字 + 状态色按 4 档 MetStatus
- **SetResult**：3 态自动判定（超过/达标/不达标），3s 自动跳 Rest
- **RestV2**（替换现 WatchRestView）：±10s 圆按钮 + 倒计时环 + **橙色描边的下一组大卡**
- **WorkoutDone**：4 格 stat + 「同步到 iPhone」CTA

## What

- 完整重写 5 个 V2 stub view 到设计稿的像素规格
- 重写 `WatchLiveWorkoutView` body 到 V2 LiveSet 视觉规格（保留现有 controller 接通逻辑）
- 重写 `WatchRestView` body 到 V2 RestV2 视觉规格（保留倒计时计数 / haptic 触发逻辑）
- 把现有调用站从 `nav.push(.liveWorkout(exerciseId:weightKg:))` / `.rest(secondsRemaining:)`
  改为新的 V2 链路：SetReady → LiveSet → SetResult → RestV2 → SetReady（下一组）→ … → WorkoutDone
- WorkoutDone 内调用 `controller.completeWithFeedback(rpe:notes:)` + `WatchConnectivityService.shared.send(.workoutSnapshot(...))`

## Impact

- 新增 capability：`watch-v2-set-flow`
- 改动文件主要在 `VBTrainerWatch Watch App/Views/WatchScreens.swift`（V2 view 完整化）
- 不删 V1 view（commit 4 的事）
- 零数据迁移、零新依赖
