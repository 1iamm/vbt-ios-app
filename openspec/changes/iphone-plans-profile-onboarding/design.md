## Context

Plans + Profile 是 iOS 端最后两个 tab。Onboarding 决定首次用户体验。

## Goals / Non-Goals

**Goals:**
- 用户能创建/编辑/删除模板
- 用户能查看和修改全部画像数据 + 设置
- 用户首次启动有完整引导，结束后落 UserProfile 单例

**Non-Goals:**
- 不实现计划真实下发 Watch（Proposal 9）
- 不实现 HealthKit 真实读取（Proposal 7，本 proposal 只申请权限）
- 不做 CSV/JSON 实际导出（Proposal 10）

## Decisions

### D1: Onboarding 触发条件

`UserProfile` 单例不存在时显示 Onboarding；存在时直接进 RootView。`@AppStorage` 标记 hasCompletedOnboarding 作为兜底。

### D2: 设置 List 风格

iOS 原生 `Form` + `Section`，最大化系统美学。

### D3: 论文引用页

`CitationsListView` 列出 `Citations.all`，每条点击 `Link` 跳浏览器。
