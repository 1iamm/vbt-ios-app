## ADDED Requirements

### Requirement: Snapshot ↔ SwiftData 双向转换

The system SHALL provide `WorkoutStore` with two methods:
- `save(_ snapshot: WorkoutSnapshot, in context: ModelContext) throws -> Workout`
- `snapshot(of workout: Workout) -> WorkoutSnapshot`

The conversion preserves: id, exerciseId, startedAt, endedAt, all sets, all reps, heart-rate samples (heart rate samples are written to a JSON-encoded blob attribute on Workout — see ARCHITECTURE doc for rationale), rpe, linkedTemplateId, notes.

#### Scenario: Round-trip equality

- **WHEN** a snapshot is saved and re-read via `snapshot(of:)`
- **THEN** the resulting snapshot equals the original (modulo timestamps that may have lost sub-millisecond precision)

### Requirement: 重复 ID 去重

`save(_:)` SHALL skip insertion if a Workout with the same `id` already exists, returning the existing Workout instead.

#### Scenario: Duplicate save

- **WHEN** `save(_:)` is called twice with the same snapshot id
- **THEN** the second call returns the existing Workout without inserting
