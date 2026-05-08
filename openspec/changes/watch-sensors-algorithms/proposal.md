# Proposal: Watch Sensors & Algorithms

## Why

Watch 端是 VBT 的核心数据源——IMU 100Hz 采集、心率监控、Rep 自动识别、速度计算、VL%、CMJ 跳跃高度，全部在手腕上跑。Proposal 1 已就绪数据模型，本 proposal 把"传感器→算法→数据模型"这条链路打通，让后续 UI（Proposal 3）和通信（Proposal 4）有真实数据可用。

## What Changes

- **新建** `Sensors/MotionManager.swift`：CMDeviceMotion 100Hz 采集（含 HKWorkoutSession 防降频）
- **新建** `Sensors/HeartRateManager.swift`：HealthKit 实时心率
- **新建** `Algorithms/RepDetector.swift`：基于 userAcceleration.z 的状态机 rep 识别
- **新建** `Algorithms/VelocityCalculator.swift`：积分 + ZUPT 校正速度计算（输出 MV/PV/MPV）
- **新建** `Algorithms/VelocityLossCalculator.swift`：VL% 实时计算
- **新建** `Algorithms/JumpDetector.swift`：CMJ 飞行时间法测跳跃高度
- **新建** `Algorithms/MetStatusEvaluator.swift`：根据速度区间判定达标状态（驱动震动）
- **新建** `Tests/AlgorithmTests/`：每个算法独立单测，用合成 IMU 信号验证正确性
- **新建** `Sensors/ActiveWorkoutSession.swift`：把传感器 + 算法封装成一个高层会话对象

零业务逻辑（不存数据库、不通信），全部纯算法 + 内存中流转。

## Capabilities

### New Capabilities

- `motion-capture`: CMDeviceMotion 100Hz 采集 + HKWorkoutSession 防降频
- `heart-rate-capture`: HealthKit 实时心率读取
- `rep-detection`: IMU 状态机 rep 识别
- `velocity-computation`: 积分 + ZUPT 速度计算 + MV/PV/MPV 三变量输出
- `velocity-loss`: VL% 计算（实时与最终）
- `jump-detection`: CMJ 飞行时间法测高度
- `met-status-evaluation`: 速度区间达标状态判定（驱动震动反馈）
- `active-workout-session`: 训练会话编排（开始/结束/暂停状态机）

### Modified Capabilities

（无）

## Impact

- 仅 watchOS target；iOS target 不受影响
- 新增 `WatchKit` / `CoreMotion` / `HealthKit` framework 依赖（已通过 Info.plist 权限就绪）
- 算法模块**纯 Swift**，无第三方
- 单测在 iOS test bundle 跑（合成数据，不依赖真机）
