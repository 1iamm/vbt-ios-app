# Proposal: DayPlan State Machine

## Why

来自两个 PM agent 的 Round 1 共识。当前 DayPlan 只有"有/无"二态：

- 交互视角：训后 30 秒是用户产生"这工具懂我"印象的黄金窗口。Today banner 在用户练完后仍显示"从 Watch 开始"，是 V2 整个 app 最大的破窗
- 系统视角：4 个视图（Today / Plan / Calendar / Timeline）+ 3 个 service（ReverseSyncer / AIEngine / Stats）各自用 ad-hoc 谓词推断状态，逻辑分散，无法可靠驱动反馈与下游能力

一个 enum 字段卡住 4 条下游链路。这是基础设施修复，不是新功能。

## What Changes

- **新增** `DayPlanStatus` enum（5 态）：`scheduled` / `inProgress` / `completed` / `skipped` / `missed`
- **改** `DayPlan` 模型：加 `statusRaw` + `statusUpdatedAt` 字段，`status` 计算属性，setter 同时同步 legacy `completed` Bool
- **新增** `DayPlanStateMachine` 服务：
  - `markCompleted(for:workoutDay:in:)` — 由 iPhoneConnectivityService 落库 workout 时调
  - `markInProgress(planId:in:)` — 备用入口
  - `markSkipped(planId:in:)` — 用户取消 / 日历事件被删
  - `reconcileMissed(now:in:)` — 应用启动跑一次，把过期 scheduled 转 missed
  - `backfillLegacyCompleted(in:)` — 一次性迁移
- **改** `iPhoneConnectivityService`：收到 workoutSnapshot 落库后调 `markCompleted`
- **改** `VBTrainerApp.init`：启动跑 `backfillLegacyCompleted` + `reconcileMissed`
- **改** `ScheduledTrainingCard`：从两参数 onStart/onEdit 升级为 `status + summary + onPrimary + onSecondary`，按状态切换：
  - scheduled → 「从 Watch 开始」+「编辑」（原有）
  - inProgress → 「在 Watch 上继续」（绿色徽章）+ "结束后自动同步" 提示
  - completed → 4 项数据 mini summary + 「看复盘」+「再练一次」
  - skipped → 「重新安排」（去 PlanView）
  - missed → 「补今天 / 看原计划」+ 文案 "昨日漏练"
- **改** `TodayView`：banner section title 跟状态变（已安排今日 / 训练中 / 今日已完成 / 今日跳过 / 昨日未完成）；新增 `pendingWorkoutDetail` 路由 + handlePrimary/Secondary 路由分发
- **改** `DayPlanReverseSyncer`：日历事件被删 → 改为 markSkipped 而不是 delete plan（保留历史）
- **改** `HistoryView.dotMarkers`：仅 scheduled / inProgress 才画 system-blue 已计划点

## Capabilities

### New Capabilities
- `dayplan-state-machine`

### Modified Capabilities
- `iphone-today-flow`（Banner UI 状态化）
- `iphone-history-calendar`（dot rules 用 status）
- `iphone-weekly-planner`（reverse-sync 改 mark）

## Impact

- 仅 SwiftData 加新字段（默认值兼容旧记录），无破坏性迁移
- legacy `completed: Bool` 字段保留并由 status setter 同步，下游若有读 `completed` 的代码继续工作
- Watch 端不变（不参与 DayPlan 状态判定）
- AI 推荐引擎未读 status，下次 change 切换
