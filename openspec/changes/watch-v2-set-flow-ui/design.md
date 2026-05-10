# Design

## 设计稿换算

设计稿 396×484 px = 198×242 pt（45mm @2x）。**px ÷ 2 = pt**。

## 决定

### MetStatus 4 档 → SetResult 3 态映射

| MetStatus | SetResult | 颜色 | 文案 |
|---|---|---|---|
| `.excellent` | 超过 | `.success` 绿 | 速度高于目标区间 |
| `.met` | 达标 | `fg` 白 | 速度落在目标区间 |
| `.borderline` | 达标 | `fg` 白 | 速度落在目标区间（合并到达标） |
| `.failed` | 不达标 | `.danger` 红 | 速度低于目标区间 |

设计稿原意是 borderline 也算「达标」（接近下限）；只有真正失速才标红。这与 PR #9
的 haptic 4 档不冲突——haptic 给细粒度反馈（borderline 用 directionDown），SetResult
给粗粒度判定（borderline 视觉合并到达标）。

### 自动跳转时长

- SetResult 自动 → Rest：**3 秒**（设计稿写 2s，但系统 PM 建议给 AOD 缓冲半秒）
- Rest 倒计时归 0 自动 → SetReady（下一组）：**立即**（已有 haptic 提示）

### 重写 vs 替换

`WatchLiveWorkoutView` / `WatchRestView` 的 body 完全替换。这两个 view struct 名字
保留（commit 4 才删/重命名），但内部布局用 V2 设计稿。`WatchRestView` 继续接收
`secondsRemaining: Int` 参数以兼容现有路由。

### 「下一组」预览数据来源

RestV2 的下一组卡读 `controller.nextPlannedParams` —— 已实装的方法返回
`(weightKg, reps, rest, isWarmUp)`。如果当前是最后一组，nextPlannedParams 返回
nil → 卡片隐藏，倒计时归 0 后跳转到 `.workoutDone` 而非下一组 SetReady。

### 流程

```
PlanSynced → [tap]   → SetReady
SetReady   → [tap]   → 配 controller.start(...) → LiveSet
LiveSet    → [tap]   → controller.endSet() → SetResult
SetResult  → [3s]    → RestV2 (replaceTop)
RestV2     → [0]     → SetReady (next set, replaceTop) OR WorkoutDone (last set)
RestV2     → [skip]  → 同上（直接跳过倒计时）
WorkoutDone→ [sync]  → controller.completeWithFeedback + send + popToRoot
```

### 复用现有底层（不要重写）

- `LiveWorkoutController.start / endSet / startNextSet / completeWithFeedback`
- `LiveWorkoutController.lastSetMetSummary / lastSetSnapshot / completedSets / nextPlannedParams`
- `MetStatusEvaluator.evaluate(velocity:target:)`
- `Tokens.Color.success / warning / danger / accent`
- `HapticFeedback.rep / setEnded / workoutEnded`（PR #9）
- 现有 `WatchScreenChrome` 容器壳

## 不做

- 不动算法、连接协议
- 不删 V1 view / route case（commit 4）
- 不动 Summary 页（V1 的 RPE + Feeling 评价是不同维度，保留为独立可达 view）
- 不实装 Always-On dimmed 适配像素级（后续可能 change）

## 风险与回退

- **风险**：LiveSet 的 95pt 大字在 40mm 表盘可能挤——回退方案：用 `.minimumScaleFactor(0.7)` 自适应
- **风险**：SetResult 3s 自动跳转期间用户旋表冠会取消 task — 用 `.task` 而非 `.onAppear` Task 确保 view 离场时取消
- **回退**：单 commit revert 即可，UI-only 改动，不影响数据
