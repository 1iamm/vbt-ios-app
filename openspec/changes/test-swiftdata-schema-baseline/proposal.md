# Proposal: SwiftData V1 schema baseline regression tests

## Why

Round 1 review · Reliability #1 (P0)：

> Schema migration tests 完全缺失。Workout 加字段 / Rep 改类型 / Template 关系倒置 → CI 全绿，用户升级后 SwiftData 直接拒绝加载 = 数据**永久丢失**。

V1 还没上 App Store，但马上要发 TestFlight。任何 schema PR（如 Round 1 PM-F2 多动作 Workout 改造）需要 baseline 测试兜底。

## What Changes

新增 `Tests/AlgorithmTests/SwiftDataSchemaBaselineTests.swift`：

1. **`testSchemaInventory`**：断言 `VBTSchemaV1.allModels` count 是 11，且包含每个预期类型名。新加 `@Model` 类没注册到 schema 立即挂。

2. **`testContainerInitWithFullSchema`**：实例化完整 schema 的 `ModelContainer`（in-memory）。任何 model 的 Codable 不通过都会在这里抛错。

3. **`testInsertOneOfEachAndPersists`**：每个核心 @Model（UserProfile / Workout / ReadinessSnapshot / Template / JumpTest）插入一个示例，save，再用全新 ModelContext fetch 验证 count + 字段值。覆盖：
   - 必填字段默认值
   - 关系级联
   - 跨 context 持久化

4. **`testTwoConsecutiveSavesSucceed`**：两次 `save()` 都成功，守门"computed uniqueness conflict"类问题。

## 不覆盖（明确范围）

- **磁盘 .store 迁移**：需要 fixture .store 文件 + 多版本并存。等 V1 上 TestFlight 后单独 PR 加。
- **V1→V2 migration**：V2 没启动，等到时单独写。

## Capabilities

### Added Capabilities
- `swiftdata-schema-regression-coverage`

## Impact

- 仅新增 1 个 Tests/ 文件，0 行产品代码
- 4 个新测试用例
- in-memory ModelContainer，无文件系统副作用

## Risk

无。如果产品 schema 不稳定，测试失败而不是用户损失数据——这就是测试的目的。

## Exit Criteria

- 4 个新测试在 CI 全过
- 故意修改 `VBTSchemaV1.allModels` 删一个类 → `testSchemaInventory` 立即挂（手工 dry-run 验证一次）
- 故意改 `UserProfile.age: Int → String` → `testInsertOneOfEachAndPersists` 立即挂
