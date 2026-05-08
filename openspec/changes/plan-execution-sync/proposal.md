# Proposal: Plan Execution & Watch Sync

## Why

Proposal 6 让用户能在 iPhone 上创建模板和挂日历。本 proposal 完成最后一段：
- 模板下发 Watch（用户挂到当天 → Watch 自动收到 → "今日计划" 屏幕显示）
- Watch 端按计划逐项执行
- 训练完成自动回填到计划项

## What Changes

- 扩展 `ConnectivityProtocol` 加 `TemplateSnapshot`
- 新建 `Shared/Services/TemplateSyncService.swift`：iPhone → Watch 推送
- 新建 Watch 端 `TodayPlanLoader.swift`：在 Watch 启动时拉今日计划
- 修改 `WatchPlanProgressView` / `WatchPlanNextView`：从 mock 切到真实数据
- 修改 iPhone CalendarPlanView：保存挂载时立即推 Watch

## Capabilities

- `template-sync`: iPhone → Watch 模板推送
- `plan-execution`: Watch 端按计划逐项执行

## Impact

- 仅影响 connectivity service + 两端计划相关 view
- 新增 TemplateSnapshot Codable 类型
