## Context

iPhone 是模板真源；Watch 是执行端。每天最多一份"今日计划"。

## Goals / Non-Goals

**Goals:**
- iPhone 把指定日期的模板序列化推到 Watch
- Watch 持久化"今日计划"到本地（@AppStorage 或 SwiftData）
- Watch 主页显示"今日计划"卡片（如有）

**Non-Goals:**
- 不实现"完成度自动回填到 iPhone"（先本地记录，下个版本再做双向同步）
- 不做计划版本冲突解决

## Decisions

### D1: TemplateSnapshot 简化

不传整个 Template 模型；传一个 Codable struct，只含 Watch 执行所需信息（动作 / 组数 / reps / 目标）。

### D2: Watch 本地存储

@AppStorage JSON — 简单可靠，不需要为单条记录开 SwiftData 表。

## Risks

- 推送时机：用户在 iPhone 挂日历后立即推一次 + Watch 启动时拉一次 = 双重保险
