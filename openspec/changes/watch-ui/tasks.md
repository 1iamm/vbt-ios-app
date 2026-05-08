## 1. 基础设施

- [x] 1.1 `VBTrainerWatch Watch App/Views/HapticFeedback.swift`：4 阶震动反馈引擎（含 `#if os(watchOS)` 守卫）
- [x] 1.2 `VBTrainerWatch Watch App/Views/WatchNavigation.swift`：ObservableObject + WatchRoute enum
- [x] 1.3 `VBTrainerWatch Watch App/Views/WatchTheme.swift`：补充 Watch 专属 token（订阅 Tokens 但加 OLED 黑底约定）

## 2. 主流程屏幕

- [x] 2.1 `WatchHomeView.swift`
- [x] 2.2 `WatchReadinessView.swift`（圆环风格）
- [x] 2.3 `WatchExercisePickerView.swift`
- [x] 2.4 `WatchWeightInputView.swift`（Digital Crown）
- [x] 2.5 `WatchLiveWorkoutView.swift`（核心）
- [x] 2.6 `WatchRestView.swift`
- [x] 2.7 `WatchSummaryView.swift`

## 3. CMJ 流程屏幕

- [x] 3.1 `WatchCMJCountdownView.swift`
- [x] 3.2 `WatchCMJGoView.swift`
- [x] 3.3 `WatchCMJResultView.swift`

## 4. 计划相关屏幕

- [x] 4.1 `WatchPlanProgressView.swift`
- [x] 4.2 `WatchPlanNextView.swift`

## 5. PR / 警戒 / RPE

- [x] 5.1 `WatchPRCelebrationView.swift`
- [x] 5.2 `WatchVLStopWarningView.swift`
- [x] 5.3 `WatchRPEInputView.swift`

## 6. 整合

- [x] 6.1 `WatchRootView.swift` 改用 NavigationStack + WatchNavigation
- [x] 6.2 编译 watchOS scheme → BUILD SUCCEEDED
- [x] 6.3 `openspec status --change watch-ui` 显示全 done
