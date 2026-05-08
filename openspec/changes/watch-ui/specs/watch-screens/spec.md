## ADDED Requirements

### Requirement: Home 屏幕

The system SHALL provide a `WatchHomeView` showing: app title "VBTrainer", a primary "开始训练" action, and a secondary line summarizing the last workout.

#### Scenario: Tap start

- **WHEN** the user taps "开始训练"
- **THEN** navigation pushes to ExercisePicker

### Requirement: Readiness 屏幕（圆环风格）

The system SHALL provide a `WatchReadinessView` rendering a ring (0-100 scale) with the score in its center. Tier color: green (≥80), yellow (60-79), red (<60), gray (insufficient).

#### Scenario: Score 72 → yellow

- **WHEN** `WatchReadinessView(score: 72)` is rendered
- **THEN** the ring is yellow

### Requirement: CMJ 测试三屏

The system SHALL provide three views: `WatchCMJCountdownView` (3-2-1 countdown), `WatchCMJGoView` (the moment to jump), `WatchCMJResultView` (best of 3 attempts in cm).

#### Scenario: Result shows best height

- **WHEN** `WatchCMJResultView(attempts: [28, 31, 29])` is rendered
- **THEN** the displayed best height is `31 cm`

### Requirement: 选动作屏幕

The system SHALL provide `WatchExercisePickerView` listing exercises grouped by category (杠铃 / 哑铃 / 自重 / 器械 / 跳跃) using `ExerciseLookup.grouped`.

#### Scenario: Picker shows all 30

- **WHEN** the picker is rendered
- **THEN** total visible items count is 30

### Requirement: 输重量屏幕

The system SHALL provide `WatchWeightInputView` with Digital Crown driving a Double weight value. The increment step is the user's `crownStep` setting (default 2.5 kg).

#### Scenario: Crown rotation

- **WHEN** the user rotates the crown by one notch with crownStep=2.5
- **THEN** weight changes by 2.5 kg

### Requirement: LiveWorkout 屏幕

The system SHALL provide `WatchLiveWorkoutView` showing: top — exercise name + weight; center — last rep velocity in huge numerals colored by MetStatus; below — rep count + heart rate; bottom — "结束本组" button.

#### Scenario: Excellent state

- **WHEN** `metStatus = .excellent`
- **THEN** the velocity number is rendered in `Tokens.Color.success` (green)

### Requirement: Rest 屏幕

The system SHALL provide `WatchRestView` with a circular countdown ring + remaining seconds in the center; above shows last set summary; below shows next-set weight suggestion.

#### Scenario: Countdown progress

- **WHEN** rest = 90 total, remaining = 45
- **THEN** the ring is approximately 50% filled

### Requirement: Summary 屏幕

The system SHALL provide `WatchSummaryView` showing total reps, average velocity, average VL%, and average heart rate, plus a "完成" button that returns to Home.

#### Scenario: Numbers shown

- **WHEN** `WatchSummaryView(totalReps: 18, avgVelocity: 0.58, avgVL: 18, avgHR: 138)` is rendered
- **THEN** all four numbers are visible

### Requirement: 计划相关屏幕

The system SHALL provide `WatchPlanProgressView` (vertical timeline of plan items, current marked) and `WatchPlanNextView` (next exercise + weight + sets).

#### Scenario: Plan progress shows position

- **WHEN** plan has 4 items and current is item 2
- **THEN** the current item visual indicator is on item 2

### Requirement: PR / VL 警戒 / RPE 屏幕

The system SHALL provide:
- `WatchPRCelebrationView` (PR detected, displays type + value, auto-dismisses after 3s)
- `WatchVLStopWarningView` (VL exceeded ceiling, two buttons: 继续 / 结束)
- `WatchRPEInputView` (1-10 picker via Digital Crown, post-set subjective rating)

#### Scenario: VL warning emits action

- **WHEN** the user taps "结束" on `WatchVLStopWarningView`
- **THEN** the view's onEnd closure is called
