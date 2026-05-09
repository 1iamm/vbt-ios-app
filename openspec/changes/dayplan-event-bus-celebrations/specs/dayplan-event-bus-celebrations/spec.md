## ADDED Requirements

### Requirement: DayPlanEventBus single source

`DayPlanEventBus.shared.stream` SHALL be the single subscription point for
DayPlan lifecycle events. The bus uses `AsyncStream(bufferingPolicy:
.bufferingNewest(32))`. Events: `.completed(planId, workoutId?)` /
`.inProgress(planId)` / `.skipped(planId)` / `.missed(planIds)`.

### Requirement: State machine publishes after each transition

Every successful state transition in `DayPlanStateMachine` SHALL call
`DayPlanEventBus.shared.publish(...)` with the matching event AFTER the
context save completes.

#### Scenario: Completing today's plan emits event

- **WHEN** markCompleted flips status to .completed and saves
- **THEN** the next iterator on DayPlanEventBus.shared.stream yields .completed with the plan id

### Requirement: Reverse syncer routes through state machine

`DayPlanReverseSyncer.runReconcile()` SHALL invoke
`DayPlanStateMachine.markSkipped` (NOT mutate `plan.status` directly) when
a calendar event was deleted. This guarantees `.skipped` events are
published.

### Requirement: Weekly adherence aggregation

`WeeklyAdherenceCalculator.compute(for:context:)` SHALL return a
`WeeklyAdherence` with counts of all 5 statuses for the ISO week of the
reference date (Monday-first). `isFullyCompleted` is true iff `planned > 0
&& completed == planned`.

#### Scenario: 5 of 7 planned days completed, 2 still scheduled

- **WHEN** Mon/Tue/Wed/Fri/Sat completed and Thu/Sun planned but future
- **THEN** WeeklyAdherence has planned=7, completed=5, current=2, isFullyCompleted=false

### Requirement: Streak calculation tolerates rest days

`WeeklyAdherenceCalculator.currentStreak` SHALL count consecutive
completed DayPlans walking backwards from today. A day with no DayPlan
(rest) is neutral and does NOT break the streak. A `.missed` or
`.skipped` day DOES break it.

#### Scenario: 3 completed weekdays followed by 2 rest days

- **WHEN** Mon/Tue/Wed completed, Thu/Fri have no DayPlan, today is Fri
- **THEN** currentStreak == 3

### Requirement: CelebrationCard renders 4 kinds

`CelebrationCard` SHALL render one of: `.prBeaten` (icon trophy),
`.weeklyFullyCompleted` (icon checkmark.seal), `.streakMilestone` (icon
flame), `.generic` (icon checkmark.circle). Background is an accent-color
linear gradient with shadow. The card includes haptic.success on appear,
swipe-to-dismiss, and an X close button.

### Requirement: CelebrationResolver priority

`CelebrationResolver.resolve(completedWorkoutId:context:)` SHALL choose
in this priority order:

1. PR detected for the workout id → `.prBeaten`
2. Weekly fully completed → `.weeklyFullyCompleted`
3. Current streak ∈ {3, 7, 14, 30, 60, 100} → `.streakMilestone`
4. Otherwise → `.generic`

Only one Kind is returned per call; subsequent rules don't fire.

### Requirement: Today shows weekly progress strip

`TodayView` SHALL render `WeekProgressStrip` between the header and the
banner whenever `WeeklyAdherenceCalculator.compute` returns `planned > 0`.
The strip displays 7 dots (Mon-first) colored by status:

- completed → accent fill
- inProgress → success fill + white border
- scheduled → accent 18%-opacity fill + accent stroke
- skipped → tertiary 50% fill
- missed → warning stroke
- no plan → neutral fill (smaller dot)

A short caption to the right reads one of: "满训" / "已漏 N" / "跳过 N" /
"训练中" / "进行中".

### Requirement: Today celebrates on completion event

`TodayView` SHALL subscribe to `DayPlanEventBus.shared.stream` and, upon a
`.completed` event, invoke `CelebrationResolver.resolve` and present the
returned Kind as an animated overlay at the top of the screen for 6
seconds (or until manually dismissed via swipe / X).

#### Scenario: Beat a PR completes today's plan

- **WHEN** Watch finishes a workout that triggers a new PR record
- **AND** iPhoneConnectivityService → markCompleted → publishes .completed
- **THEN** TodayView overlays CelebrationCard with kind=.prBeaten and accent gradient

### Requirement: Stats narrative line

`StatsView` headline card SHALL render a one-line narrative summary above
the 4-tile grid. The line composes from `WeekOverWeekHeadline` and
`WeeklyAdherence`:

- `isFullyCompleted` → "本周满训 (N/N)"
- otherwise: "已完成 N/M" (+ "漏 X" if missed > 0)
- volume |Δ| ≥ 5% → "训练量高于/低于上周 X%"
- velocity |Δ| ≥ 3% → "平均速度更快/略慢"

Empty data → "本周训练数据建立中".

#### Scenario: 5/7 completed with 8% volume increase

- **THEN** the narrative reads "已完成 5/7 · 训练量高于上周 8%"
