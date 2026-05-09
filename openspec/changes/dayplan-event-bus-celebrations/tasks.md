## 1. 事件流
- [x] 1.1 新增 `DayPlanEventBus.swift`（AsyncStream + bufferingNewest(32)）
- [x] 1.2 `DayPlanStateMachine` 每个 mutation 后 publish
- [x] 1.3 `DayPlanReverseSyncer` 改走 markSkipped 而非直接 mutate

## 2. 聚合
- [x] 2.1 新增 `WeeklyAdherence.swift`（struct + Calculator + currentStreak）

## 3. UI 反馈
- [x] 3.1 新增 `CelebrationCard.swift`（4 种 Kind + Resolver + haptic + swipe dismiss）
- [x] 3.2 新增 `WeekProgressStrip`（7 dots × status colors）
- [x] 3.3 `TodayView` 加 weekStripCard
- [x] 3.4 `TodayView` 订阅 EventBus → 6s 庆祝 overlay
- [x] 3.5 `StatsView` headline 加 narrativeLine

## 4. 编译/真机
- [ ] 4.1 用户 macOS 本机 `xcodebuild` 通过
- [ ] 4.2 真机：训完后看到 Today 顶部弹 CelebrationCard（按优先级）
