## 1. Sensor Layer

- [x] 1.1 创建 `VBTrainerWatch Watch App/Sensors/MotionSample.swift`：值类型 `MotionSample(timestamp, userAccel, attitude)`
- [x] 1.2 创建 `VBTrainerWatch Watch App/Sensors/MotionManager.swift`：`actor MotionManager` 含 `start()` / `stop()` / `stream` AsyncStream
- [x] 1.3 实现 HKWorkoutSession 包装：开 traditional strength training session
- [x] 1.4 创建 `VBTrainerWatch Watch App/Sensors/HeartRateManager.swift`：actor，HKAnchoredObjectQuery 心率订阅
- [x] 1.5 创建 `VBTrainerWatch Watch App/Sensors/SyntheticMotionGenerator.swift`：生成合成 IMU 信号供测试

## 2. Algorithms

- [x] 2.1 创建 `VBTrainerWatch Watch App/Algorithms/RepEvent.swift`：值类型，含 reps 内的速度数组、概要数据
- [x] 2.2 创建 `VBTrainerWatch Watch App/Algorithms/RepDetector.swift`：状态机 + 阈值常量 + ZUPT 触发
- [x] 2.3 创建 `VBTrainerWatch Watch App/Algorithms/VelocityCalculator.swift`：梯形积分 + ZUPT + MV/PV/MPV 计算
- [x] 2.4 创建 `VBTrainerWatch Watch App/Algorithms/VelocityLossCalculator.swift`：VL% + 警戒线判定
- [x] 2.5 创建 `VBTrainerWatch Watch App/Algorithms/JumpDetector.swift`：CMJ 飞行时间法
- [x] 2.6 创建 `VBTrainerWatch Watch App/Algorithms/MetStatusEvaluator.swift`：纯函数 + 单测覆盖
- [x] 2.7 每个算法常量加 `/// Reference: Citations.xxx` 注释

## 3. ActiveWorkoutSession 编排

- [x] 3.1 创建 `VBTrainerWatch Watch App/Sensors/ActiveWorkoutSession.swift`：actor，composes Motion + HR + RepDetector + VelocityCalculator
- [x] 3.2 实现状态机 idle / running / resting / completed
- [x] 3.3 实现 `start / endSet / startNextSet / complete` API
- [x] 3.4 实现事件流 `eventStream: AsyncStream<SessionEvent>`（repCompleted / restTick / setEnded / sessionEnded / vlCeilingExceeded）
- [x] 3.5 创建 `WorkoutSnapshot.swift`：值类型，session 完成时输出，供 Proposal 4 持久化

## 4. Tests

- [x] 4.1 创建 `Tests/AlgorithmTests/MetStatusEvaluatorTests.swift`：覆盖 4 种状态判定
- [x] 4.2 创建 `Tests/AlgorithmTests/VelocityLossTests.swift`：覆盖公式 + 警戒线
- [x] 4.3 创建 `Tests/AlgorithmTests/VelocityCalculatorTests.swift`：常量加速度 + ZUPT 行为
- [x] 4.4 创建 `Tests/AlgorithmTests/RepDetectorTests.swift`：合成 5 reps / 静态信号 / 抖动
- [x] 4.5 创建 `Tests/AlgorithmTests/JumpDetectorTests.swift`：合成 30cm 跳跃、3 attempts best
- [x] 4.6 删除占位 `PlaceholderTests.swift`

## 5. 编译与验证

- [x] 5.1 重跑 `xcodegen generate`
- [x] 5.2 编译 watchOS target → BUILD SUCCEEDED
- [x] 5.3 编译 iOS target → BUILD SUCCEEDED（Tests 在 iOS bundle 跑）
- [x] 5.4 跑单测：watchOS target 不需要 simulator 的算法测全部通过（用 `xcodebuild test -sdk iphonesimulator` 在 iOS 跑）— **如果 simulator 还没下载完，仅做编译验证，跑测试推迟到 simulator 就绪后**
- [x] 5.5 `openspec status --change watch-sensors-algorithms` 显示全 done
