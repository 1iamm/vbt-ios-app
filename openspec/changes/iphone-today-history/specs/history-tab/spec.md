## ADDED Requirements

### Requirement: History 列表

`HistoryView` SHALL display all stored workouts grouped by calendar day, newest first. Each row shows: exercise name, total reps, average velocity, peak heart rate.

#### Scenario: Tap row

- **WHEN** the user taps a row
- **THEN** navigation pushes `WorkoutDetailView(id:)`

### Requirement: 单次训练详情

`WorkoutDetailView` SHALL show:
1. Header summary (total reps / avg velocity / VL% / duration)
2. The `ComprehensiveChartView`
3. A heart-rate-zones donut
4. Per-set table (weight / reps / avg velocity / peak velocity / VL%)

#### Scenario: Empty data graceful

- **WHEN** a workout has no reps recorded
- **THEN** the detail view shows the data it has and a "未采集" badge for missing fields
