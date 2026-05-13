# Proposal: V1 项目代码结构重构（功能不变）

## Why

V1 进入收尾阶段（83+ Swift 文件、~8.7k LOC）。多轮快速迭代后积累了：
- **孤儿代码**（如 `WatchPRCelebrationView`、`HeartRateZonesDonut`，存在但未引用）
- **重复组件**（4 处 round 卡片、3 处 primary CTA、2 处 KPI tile，手搓而非复用）
- **目录散布**（部分 SwiftUI 组件在 Services 目录，部分服务在 Views 目录）
- **OpenSpec 未归档** completed changes 留在 `openspec/changes/`（应 V1 完成时统一归档进 `openspec/specs/`）

Task 3 = 在 Task 2 主要 UX 修复落地后，做**一次系统性整理**，让 V1.5 云同步开始前的代码库可读、可维护、最小化。

## What Changes

按 round 推进：

### Round 1：3 Agent Audit
- **架构师 agent**：模块边界 / 依赖方向 / 抽象层次 / 跨平台代码组织
- **性能 agent**：算法热点 / SwiftUI 重渲染 / SwiftData 查询效率 / 内存
- **测试 agent**：测试覆盖盲区 / 难测代码（强耦合 service）/ 假数据生成器复用

### Round 2：重构设计
- 输出 ADR / migration 方案
- 文件移动 / rename / 拆分 / 合并清单
- 标记可删除的孤儿代码

### Round 3：执行
- 按设计批量改
- 现有 UI test + algorithm test 必须 100% 仍绿
- LOC 净减、circular dep 清零、孤儿代码全删
- OpenSpec changes 完成的归档到 `openspec/specs/`
- 本 change 自己也归档

## Capabilities

不增不减 capability（功能不变）。仅 modify 现有 capability 的内部组织。

## Impact

- **大量**文件移动 / rename
- **少量**真正的代码逻辑改动（限于消除重复 / 提取共用）
- SwiftData schema **不动**
- 用户可见行为 **不变**
- 测试 **不删**，但可重组路径

## Exit Criteria

3 agent 复审（架构 / 性能 / 测试）一致通过：
- 0 个孤儿代码（grep 验证）
- 0 个循环依赖
- LOC 净减或与原持平（即使加了抽象层）
- 现有所有测试仍绿
- OpenSpec changes 目录干净（completed → archived）
- CLAUDE.md 反映最新代码结构（架构图 + 关键路径更新）

## Pre-requisite

- Task 2 substantively 完成（至少 P0 全 done，P1 大部分 done）
- 否则边重构边改业务，diff 难审

## Risk

- Schema migration 风险：如 Task 2 改了 Workout 模型为多动作，Task 3 不再动 schema 但要确保迁移路径文档化
- SwiftUI Preview 可能因文件移动失效 → 用 `xcodegen generate` 自动重建
