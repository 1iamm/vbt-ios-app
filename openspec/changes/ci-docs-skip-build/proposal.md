# Proposal: docs-only PR 跳过整个 macOS build/test job

## Why

来自 PR #9 Round 1 终审：
- **DX F8 P1**：docs-only / openspec-only PR 跑 ~6 min macOS build/test 浪费
- **Cost #2 P0**：每 docs PR 浪费 ~5-7 min macOS 分钟

PR #56 加了"has_ui" 跳过 UI test 段（5-7 min），但 build iOS + build watchOS + algorithm test 仍跑。当前 docs/openspec PR 仍 ~6 min。

OpenSpec exit criteria 明文："文档 / OpenSpec / 注释类 PR 跳过 macOS build（< 1 min 完成）" —— 当前违规。

## What Changes

`.github/workflows/ci.yml`:

1. **fast-fail job 新增 outputs**：
   - `has_native_code`：任何 `.swift` / `project.yml` / `Signing.xcconfig` / `.swiftlint.yml` / `.swiftformat` / entitlements / `ci.yml` 改动 → true
   - `has_ui`：上述 + UI / View / Schema 改动 → true（既有逻辑）

2. **Detect change scope step 从 build-test 移到 fast-fail**：在 Linux 上算（更快、更便宜）。

3. **build-test job 加 job 级 `if: needs.fast-fail.outputs.has_native_code == 'true'`**：
   - true → 跑完整 macOS pipeline（编译 + 算法测试 + 可能 UI test）
   - false → 整个 macOS job skipped，GitHub UI 显示「Skipped」（不算失败）

4. **所有 `steps.changes.outputs.has_ui` → `needs.fast-fail.outputs.has_ui`**：因为 scope 检测移到上一个 job。

## Capabilities

### Modified Capabilities
- `ci-fast-fail`

## Impact

| PR 类型 | 之前 | 之后 |
|---|---|---|
| 纯 docs / openspec | ~6 min | **~30s**（仅 Linux fast-fail）|
| Algorithm / Service 改动 | ~7-8 min | ~7-8 min（不变）|
| UI 改动 | ~10-12 min | ~10-12 min（不变）|

## Risk

- **误判风险**：如果 `nativeRE` regex 漏覆盖某种"实际影响 build 的"文件，build-test 被跳过 = 漏验证
- **当前 regex 覆盖**：`.swift` / `project.yml` / `Signing.xcconfig` / `.swiftlint.yml` / `.swiftformat` / `*.entitlements` / `ci.yml`
- 反例：如果加新 Swift Package（V1 不允许）或新 Asset，需要扩 regex

## Exit Criteria

- 本 PR 自己 dogfood：只改 `ci.yml` + openspec → has_native_code = true（因为 `ci.yml` 在白名单）→ 仍跑 build 验证
- 下个纯 docs PR（如 openspec-only）：should `has_native_code = false` → skip macOS → < 1 min CI
