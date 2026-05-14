# Proposal: WatchConnectivity 全协议契约测试

## Why

Round 1 review · Reliability #3 (P0)：

> WatchConnectivity 协议没有契约测试。`StartWorkoutCodecTests.swift` 只测一端编解码，不测"iOS 编 → Watch 解"的跨端对称。改 `StartWorkoutMessage` 字段名 / `MessageType` enum case，单端编译通过、运行时 Watch 收到丢字段崩溃。

V1 整个跨端数据流（开始训练 / 同步 workout / 推送 LiveProgress / 改 rest 倒计时 / 远程结组）都靠 `ConnectivityMessage` 这一个 codec。任何 case rename / 字段添加 / 类型改变都得有契约测试兜底。

## What Changes

新增 `Tests/AlgorithmTests/ConnectivityContractTests.swift`：

8 个 `ConnectivityMessage` case 全部覆盖 roundtrip：
- `.workoutSnapshot`
- `.jumpTest`
- `.template`
- `.preferences`（true / false 两个 bool 分支都跑）
- `.startWorkout`
- `.liveProgress`（含 5 个 Phase enum case 穷举）
- `.restAdjust`
- `.setControl`（含 3 个 Action enum case 穷举）

加上：
- `testKindTagsCoverAllCases`：枚举 8 个 case，强制断言 `samples.count == 8` —— 添加新 ConnectivityMessage case 而忘了写测试时**直接挂**
- `testDecodeRejectsCorruptedPayload`：损坏 payload 应抛 error
- `testDecodeReturnsNilOnMissingPayload`：缺 payload key 返 nil 不抛

## Capabilities

### Modified Capabilities
- `connectivity-codec-contract`

## Impact

- 仅新增一个 test 文件，无产品代码改动
- 现有 `StartWorkoutCodecTests` 保留不动（功能上有重叠但不冲突）
- 跑测试时间：~1s 增加（13 个新测试用例）

## Risk

- 无。如果产品代码不稳定，测试会失败而不是产品挂——这正是测试的目的

## Exit Criteria

- CI 跑通 `ConnectivityContractTests`，13 个用例全过
- 未来任何修改 `ConnectivityMessage` / `ConnectivityCodec` 的 PR 必须连带更新此测试，否则失败
