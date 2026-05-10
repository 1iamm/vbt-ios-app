# watch-v2-set-flow

## Purpose

V2 训练单组流程的视觉与交互合约：从 PlanSynced 看到清单 → SetReady 准备 → LiveSet 训练 →
SetResult 自动判定 → RestV2 休息 → 循环到 WorkoutDone。

## Requirements

### PlanSyncedView

- SHALL 用 ScrollView + Crown 作主滚动容器
- SHALL 按动作分组：每组以动作名 11pt 大标题开头，右侧以 7pt sub 显示「休 Ns · K 组」
- SHALL 在每组下方缩进显示每一组的 `N/K   weight × reps`，monospaced digits
- 当前组（`controller.plannedSetCursor` 对应）SHALL 用橙色 1.5pt 描边 + 12% 橙色底高亮
- 已完成组 SHALL 灰化 + 删除线
- SHALL 显示底部 sub 文字「在手机点击开始」（V2 主张手机主导）
- 点击当前组的「卡片」SHALL `nav.push(.setReady)`

### SetReadyView

- 顶部 StatusBar SHALL 显示「第 N / 总 组」橙色 7pt
- 中部 SHALL 显示动作名 28pt + 重量 39pt + 「目标 N reps · MV X-X m/s」9pt sub
- 底部全宽 capsule 主按钮 SHALL 是 `Tokens.Color.accent` 实底，高 32pt，文案「⚡本组开始」
- 点击 SHALL 调 `controller.start(...)` + `nav.push(.liveWorkout)`

### LiveSetView（替换 WatchLiveWorkoutView body）

- 顶部双行：左 9pt 「动作 · 重量」、右 9pt 状态色文案（优秀/达标/偏慢/未达标）
- 主数字 SHALL 95pt monospaced，按 `controller.metStatus` 4 档着色（绿/白/橙/红）
- 主数字下方 SHALL 显示 m/s 单位 16pt
- 下排 SHALL 横向均分 REPS 21pt monospaced + 心率（heart 图标 + 21pt）
- 底部 SHALL 是 30pt 红色 capsule「结束本组」
- 点击 SHALL 调 `controller.endSet()` + `nav.push(.setResult)`
- SHALL 保留 Digital Crown 切 mode 的现有逻辑（velocity / vl / hr）

### SetResultView

- 顶部 StatusBar SHALL 显示「本组结果」状态色
- 中部 SHALL 显示 76pt 直径状态圆形图标（按 3 态映射颜色 + icon）
- 主文案 SHALL 28pt：「超过」/「达标」/「不达标」按状态色
- 副文案 SHALL 7pt sub：「速度高于/在/低于目标区间」
- 双格 stat：「本组 MV」`controller.lastSetMetSummary?.mv` 11pt
  / 「目标」`currentTargetRange` 8pt
- 底部 sub：「3s 后自动进入休息」
- SHALL 在 `.task` 内 `try? await Task.sleep(nanoseconds: 3_000_000_000)` 后调
  `nav.replaceTop(with: .rest(secondsRemaining: controller.currentRestSeconds))`

### RestV2View（替换 WatchRestView body）

- 顶部水平 3 列：左 28pt -10s 圆按钮、中 89pt 倒计时环、右 28pt +10s 圆按钮
- 倒计时环内 35pt m:ss monospaced 大字
- ±10s 按钮 SHALL clamp 倒计时 ≥ 5s 且 ≤ 600s
- 下方橙色描边大卡 SHALL 显示下一组：
  - 顶部一行：左「下一组」橙色 chip 7pt + 右 `N/totalSets` 7pt monospaced
  - 主行：左 18pt 动作名 + 右 19pt 重量 + 8pt × + 16pt reps
- SHALL **不**显示「上组评价 / 重量建议 / 下一组按钮」（设计稿明确删除）
- 倒计时归 0 SHALL 触发 `HapticFeedback.restEnded()` 后自动：
  - 若 `controller.nextPlannedParams != nil` → `nav.replaceTop(with: .setReady)`
  - 否则 → `nav.replaceTop(with: .workoutDone)`

### WorkoutDoneView

- 顶部 28pt 圆形 check 图标，绿色描边
- 中部 4 格 stat 网格（2 列 × 2 行）：总组数 / 总 reps / 训练量 (kg) / 用时
  - 数值 15pt monospaced + label 6pt
- 底部 28pt 高 capsule 主按钮，绿色 18% 透明底，文案「同步到 iPhone」
- 点击 SHALL：
  - `let snap = await controller.completeWithFeedback(rpe: nil, notes: nil)`
  - `WatchConnectivityService.shared.send(message: .workoutSnapshot(snap))`
  - `nav.popToRoot()`

## Behaviour

#### Scenario: 用户从 PlanSynced 走完一组
- **WHEN** 用户点 PlanSynced 当前组的卡片
- **THEN** 进 SetReady → 点「本组开始」→ LiveSet 显示实时速度
- **AND** 点「结束本组」→ SetResult 显示 3 态 → 3s 自动跳 RestV2
- **AND** RestV2 倒计时 → 自动跳到下一组 SetReady（或 WorkoutDone）

#### Scenario: 不达标的组
- **WHEN** controller.metStatus = .failed 且 lastSetMetSummary.mv < target.lowerBound
- **THEN** SetResult 显示红色「不达标」+「速度低于目标区间」副文案

#### Scenario: 最后一组完成
- **WHEN** RestV2 倒计时归 0 且 `controller.nextPlannedParams == nil`
- **THEN** `nav.replaceTop(with: .workoutDone)`
