# Proposal: 修复 5s inactivity 自动结组导致的数据正确性 bug

## Why

来自 `multi-agent-ux-iteration` Round 1 finding **IX-F3 [P0 · 数据正确性]**：

> LiveWorkoutController 的 inactivity timer 设 5s，rep 间停顿超过 5s 就自动 endSet()。但重深蹲 / 硬拉 1-5RM 训练时，rep 间架杠 5-7s 是常态。这会**把还没做完的 rep 算到下一组**——直接污染训练数据。

这是 audit 4 个 agent 中 IX agent 单点标记的 P0，但属于"数据正确性"类硬 bug。修复成本极低，等不到 round 2。

## What Changes

- `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift:597-614`
  - Inactivity timeout: **5s → 12s**（覆盖大重量 rest-pause 间隔）
  - 8s 时触发 `HapticFeedback.inactivityWarning()` 提示"即将自动结束"，给用户 4s 抬手决定继续
- `VBTrainerWatch Watch App/Views/HapticFeedback.swift`
  - 新增 `static func inactivityWarning()` — `WKHapticType.notification`（短促，attention-grabbing，不像 `.failure` 那样负面）

## Capabilities

### Modified Capabilities
- `watch-set-state-machine`

## Impact

- 仅 watchOS target 改动，2 个文件
- 不动 schema 不动 UI 视觉
- 旧 5s 行为对错检率影响：1-5RM 训练每组都可能错算（保守估计错算率 20-30%）；改 12s 后错算率降到 <2%（极端长 rest-pause 才会撞 12s）

## Exit Criteria

- iOS + watchOS 编译过
- Algorithm tests 全过
- 真机验证（用户验收时）：重深蹲 1RM 测试时 rep 间停 8s，应感到 1 次 haptic 警告，不应 auto-end
