## 1. HealthKit Read

- [x] 1.1 `Shared/Services/HealthKitService.swift` — actor + 6 async 方法
- [x] 1.2 平台守卫（#if canImport(HealthKit)）

## 2. Readiness 计算

- [x] 2.1 `Shared/Services/ReadinessCalculator.swift` — 纯函数 + 公式
- [x] 2.2 `Shared/Services/ReadinessRefresher.swift` — 调度器
- [x] 2.3 `Tests/AlgorithmTests/ReadinessCalculatorTests.swift`

## 3. UI 接入

- [x] 3.1 修改 `TodayView` — 在 .task 里调 ReadinessRefresher
- [x] 3.2 删除 ReadinessRingCard 占位 mock，改用真实数据

## 4. 编译

- [x] 4.1 xcodegen + iOS BUILD SUCCEEDED
- [x] 4.2 openspec status 全 done
