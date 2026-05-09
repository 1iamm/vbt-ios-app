# Proposal: Template Per-Set Protocol + Watch Multi-Set Flow

## Why

PR #2 在 iPhone 端给 Template 加了 `TemplateSetSpec`（每组独立调重量/次数/休息），但 `TemplateSnapshot` / `TemplateItemSnapshot` 协议没扩，Watch 端只看到旧的 `targetSets × targetReps @ targetWeightKg`，所有组用同一个重量。

用户在 Plan 编辑器里精心配置了金字塔加重 / 不同休息后，到 Watch 上还是平均参数 — 与"每组独立调"诉求不符。本 change 把协议补上并让 Watch 真用每组的参数。

## What Changes

- **改** `Shared/Services/ConnectivityProtocol.swift`：
  - 新增 `TemplateSetSpecSnapshot`（id / index / kindRaw / weightKg / reps / restSeconds）
  - `TemplateItemSnapshot` 加 `setSpecs: [TemplateSetSpecSnapshot]` 字段（默认 []，向下兼容）
  - 加便捷方法 `paramsForSet(_:)` / `effectiveWorkSetCount` / `totalSetCount`
- **改** `Shared/Services/TemplateSyncService.swift`：从 `TemplateItem.orderedSetSpecs` 序列化每组规格写入 snapshot
- **改** `VBTrainerWatch Watch App/Views/LiveWorkoutController.swift`：
  - 新增 `plannedSpecs / plannedSetCursor / lastResolvedRest`
  - 新增 `preparePlanned(item:)`：从 snapshot 填充 currentExerciseId / Weight / VLCeiling / target range，并加载 specs
  - `start(...)` 在 plannedSpecs 非空时不覆盖 preparePlanned 设的字段；以第一组 spec 的 weight/rest 为准
  - `endSet()` 自增 `plannedSetCursor`
  - `startNextSet(...)` 改为可选参数；plan 在跑时从 `plannedSpecs[cursor]` 取下组参数
  - 新增 `nextPlannedParams` 计算属性
  - `complete()` 清理 plannedSpecs
- **改** `VBTrainerWatch Watch App/Views/WatchScreens.swift`：
  - `WatchPlanProgressView` 改为可折叠 / 展开式列表；展开后显示每组的 W/R @kg + 休息；底部 "开始本动作" 按钮调 `controller.preparePlanned(item:)` + push `.liveWorkout`
  - `WatchRestView` "下一组" 按钮改为无参 `controller.startNextSet()`，让 controller 自己决定下组参数

## Capabilities

### Modified Capabilities
- `template-snapshot-protocol`（既有 ConnectivityProtocol）— 加 setSpecs 字段
- `watch-live-workout`（PR #1 落地的 capability）— controller 增加 plan-aware API

## Impact

- **协议向下兼容**：旧 watchOS 安装收到 setSpecs 字段会忽略；旧 iOS 发出的 snapshot 没有 setSpecs，Watch 自动 fallback 到 `targetSets/Reps/Weight`
- **Watch 多动作训练流程**：现在能从 `WatchPlanProgressView` 任意 item 直接进入训练，且每组使用计划的真实参数
- **AB 测试**：用户在 iPhone 设金字塔（50/70/85/95/100% × topWeight），到 Watch 上每组 weight 真的不同，RestView "下一组" 按钮自动跳到下组
- 不动 RepDetector / VelocityCalculator / 算法层
