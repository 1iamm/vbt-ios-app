## ADDED Requirements

### Requirement: TemplateItemSnapshot carries setSpecs

`TemplateItemSnapshot` SHALL include a `setSpecs: [TemplateSetSpecSnapshot]` array. When the source `TemplateItem.orderedSetSpecs` is non-empty, every spec is mapped 1:1 (id, index, kindRaw, weightKg, reps, restSeconds). When empty, `setSpecs` is `[]` and Watch falls back to legacy fields.

#### Scenario: Pyramid template snapshot

- **WHEN** a TemplateItem has 5 setSpecs at 50/70/85/95/100 kg
- **THEN** `TemplateSyncService.snapshot(of:on:).items[0].setSpecs.count == 5`
- **AND** the kgs match in order

#### Scenario: Legacy template snapshot

- **WHEN** a TemplateItem has zero setSpecs (legacy)
- **THEN** `setSpecs == []` in the snapshot, and `targetSets/Reps/Weight` carry the data

### Requirement: LiveWorkoutController consumes plan params

`LiveWorkoutController` SHALL provide a `preparePlanned(item:)` method that, given a `TemplateItemSnapshot`, captures the per-set plan into `plannedSpecs` and pre-fills `currentExerciseId / currentWeightKg / currentTargetRange / currentVLCeiling / lastResolvedRest` from the first spec.

A subsequent `start(...)` call SHALL keep the prepared fields (does not overwrite them with the route's args).

#### Scenario: Prepare then start picks first set's weight

- **WHEN** preparePlanned is called with item whose first spec is 60 kg × 8 reps
- **AND** start(exerciseId: "back-squat", weightKg: 60) is called
- **THEN** the underlying ActiveWorkoutSession.start runs with weightKg == 60
- **AND** controller.currentWeightKg == 60

### Requirement: endSet advances plan cursor

When `LiveWorkoutController.endSet()` completes, it SHALL increment `plannedSetCursor` by 1.

#### Scenario: After 3rd set ends

- **WHEN** the user finishes the 3rd planned set and taps 结束本组
- **THEN** plannedSetCursor goes from 2 to 3 (zero-indexed)

### Requirement: startNextSet auto-uses plan params

When called with no args, `LiveWorkoutController.startNextSet()` SHALL look up `plannedSpecs[plannedSetCursor]` and pass that weight/reps/rest to the underlying actor. When `plannedSpecs` is empty, it falls back to `currentWeightKg`.

#### Scenario: Auto-step through pyramid

- **WHEN** plannedSpecs holds [50, 70, 85, 95, 100] kg, plannedSetCursor=2 (just finished 70 kg, about to start 85)
- **AND** RestView taps "下一组" calling controller.startNextSet()
- **THEN** the next set starts at 85 kg

#### Scenario: Fallback when no plan

- **WHEN** plannedSpecs is empty and the user is in an ad-hoc workout
- **AND** RestView taps "下一组"
- **THEN** the next set reuses controller.currentWeightKg

### Requirement: Plan progress view per-set list and start CTA

`WatchPlanProgressView` SHALL render each item as a foldable card. Tap to expand reveals the per-set rows (`tag · weight × reps · rest`) plus a "开始本动作" button. Tapping the button SHALL call `controller.preparePlanned(item:)` then push `.liveWorkout(exerciseId: item.exerciseId, weightKg: firstSpec.weightKg)`.

#### Scenario: Tap planned squat to start

- **WHEN** user expands the squat item and taps 开始本动作
- **THEN** controller.preparePlanned is called with the snapshot
- **AND** the .liveWorkout route is pushed with the first spec's weight

### Requirement: Cleanup on workout completion

When `LiveWorkoutController.complete()` resolves, it SHALL clear `plannedSpecs` and reset `plannedSetCursor` to 0 so the next workout starts fresh.

#### Scenario: Complete and start fresh

- **WHEN** the user completes a planned 3-set squat and then starts an ad-hoc bench press
- **THEN** plannedSpecs is empty for the new workout
