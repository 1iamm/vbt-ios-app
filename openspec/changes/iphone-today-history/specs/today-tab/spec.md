## ADDED Requirements

### Requirement: Today Tab 内容

`TodayView` SHALL show:
- Top: a `ReadinessRingCard` with the latest readiness score (or empty-state if none)
- Mid: a `WorkoutSummaryCard` for the most recent workout (or empty-state)
- Bottom: a `TrainingHeatmap` of the last 30 days

#### Scenario: Empty state shown when no data

- **WHEN** the database has no workouts and no readiness snapshots
- **THEN** TodayView displays empty-state text guiding the user to Watch

### Requirement: Readiness 圆环卡片

`ReadinessRingCard` SHALL render the score as a colored ring (per ReadinessTier) with score number in the center and three subordinate metrics below: HRV / RHR / 睡眠.

#### Scenario: Color match

- **WHEN** score is 72 (yellow tier)
- **THEN** the ring stroke color is the warning orange
