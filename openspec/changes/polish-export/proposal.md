# Proposal: Polish, Export, Final QA

## Why

V1 收尾。补齐导出 / 空状态 / 真实占位 / README 更新 / 全量编译验证。

## What Changes

- 新建 `Shared/Services/CSVExporter.swift`：单训练 + 全量导出
- 新建 `Shared/Services/JSONExporter.swift`：完整结构化导出
- 完善 ProfileView 的导出按钮：弹 ShareSheet
- 完善 EmptyStateCard 在所有 view 一致使用
- 修订 README + 把所有 proposal 的 OpenSpec 状态汇总到 README
- 全量构建验证（iOS + Watch + tests target）

## Capabilities

- `data-export`: CSV/JSON 导出
- `polish`: 一致的空状态与跨视图微交互
