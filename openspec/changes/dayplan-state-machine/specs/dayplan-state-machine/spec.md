## ADDED Requirements

### Requirement: DayPlanStatus enum

The system SHALL define a `DayPlanStatus` enum with exactly 5 cases:
`scheduled`, `inProgress`, `completed`, `skipped`, `missed`. Each case is
String-backed and Codable.

### Requirement: DayPlan owns status as the single source of truth

`DayPlan` SHALL expose `status: DayPlanStatus` as a computed property backed
by `statusRaw: String`. Setting `status` SHALL also update `statusUpdatedAt
= Date()` and keep the legacy `completed` Bool in sync (`completed = (status
== .completed)`).

### Requirement: Workout completion drives status

When `iPhoneConnectivityService` persists an inbound `WorkoutSnapshot`, it
SHALL invoke `DayPlanStateMachine.markCompleted(for:workoutDay:in:)`. If a
DayPlan exists for the same calendar day and is in `.scheduled` or
`.inProgress`, that plan's status becomes `.completed` and
`completedWorkoutId` records the new workout's id.

#### Scenario: Workout finishes on a planned day

- **WHEN** the user finishes a Watch workout matching today's DayPlan
- **THEN** the DayPlan.status becomes `.completed` and `completedWorkoutId` equals workout.id

#### Scenario: Workout on an unplanned day

- **WHEN** the user runs an ad-hoc workout with no DayPlan
- **THEN** no DayPlan is created and no status changes (markCompleted is a no-op)

### Requirement: Past scheduled plans become missed at launch

`VBTrainerApp.init` SHALL invoke `DayPlanStateMachine.reconcileMissed` on
every cold launch. Any DayPlan whose `date < startOfToday` and whose status
is still `.scheduled` SHALL be flipped to `.missed`. The transition is
idempotent.

#### Scenario: Yesterday's plan never started

- **WHEN** the user does not open the app yesterday but launches today
- **THEN** yesterday's `.scheduled` plan becomes `.missed` on launch

### Requirement: Calendar deletion marks plan skipped

When `DayPlanReverseSyncer.runReconcile()` finds a DayPlan whose
`eventKitIdentifier` no longer appears in the 训练 calendar, the plan
status SHALL transition to `.skipped` (NOT delete the row). Completed
plans are never demoted to skipped.

#### Scenario: User deletes a planned event in iOS Calendar

- **WHEN** the user deletes a 训练 event for tomorrow
- **AND** the syncer reconciles
- **THEN** tomorrow's DayPlan still exists with status == .skipped

### Requirement: Today banner is status-driven

`ScheduledTrainingCard` SHALL render different copy / CTA / colors for
each of the 5 statuses:

- `.scheduled`: badge "已安排" (accent) · primary "从 Watch 开始" · secondary "编辑"
- `.inProgress`: badge "训练中" (success) · primary "在 Watch 上继续" · footer "结束后自动同步回这里"
- `.completed`: badge "已完成" (success) · 4-stat summary mini grid · primary "看复盘" · secondary "再练一次"
- `.skipped`: badge "已跳过" (secondary) · primary "重新安排"
- `.missed`: badge "未完成" (warning) · primary "补今天 / 看原计划" · footer "昨日漏练，可以以原计划补做或跳过"

#### Scenario: Completed banner shows summary

- **WHEN** today's DayPlan is .completed and links to a Workout with 62 min / 11 200 kg / 16 sets / VL=18%
- **THEN** the banner mini-grid renders 62 / 11.2 t / 16 / 18%

#### Scenario: Tapping 看复盘 navigates to detail

- **WHEN** banner status == .completed and user taps the primary CTA
- **THEN** TodayView pushes WorkoutDetailView with the linked workout id

### Requirement: Banner section title reflects status

`TodayView` SHALL choose the section header above the banner from the
status-derived map: scheduled→已安排今日 / inProgress→训练中 /
completed→今日已完成 / skipped→今日跳过 / missed→昨日未完成.

### Requirement: Calendar dots use status

`HistoryView.dotMarkers` SHALL render the system-blue 已计划 dot ONLY for
DayPlans whose status is `.scheduled` or `.inProgress`. `.skipped` and
`.missed` plans get no dot in the calendar grid.

#### Scenario: Skipped day has no dot

- **WHEN** a DayPlan on May 9 has status == .skipped and no Workout exists for that day
- **THEN** May 9 in the History calendar has no event dot below the digit
