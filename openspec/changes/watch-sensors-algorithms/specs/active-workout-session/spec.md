## ADDED Requirements

### Requirement: 高层会话编排

The system SHALL provide an `ActiveWorkoutSession` actor that composes MotionManager + HeartRateManager + RepDetector + VelocityCalculator into a single high-level API for the UI to drive.

States: `.idle / .running(setIndex:) / .resting / .completed`.

#### Scenario: Start emits running state

- **WHEN** `session.start(exerciseId: "back-squat", weightKg: 100)` is called
- **THEN** `session.state` becomes `.running(setIndex: 1)`
- **AND** the session begins emitting `.repCompleted` events as reps occur

### Requirement: 组间休息

`session.endSet()` SHALL transition state to `.resting` and start a countdown based on the user's default rest seconds.

#### Scenario: Rest countdown

- **WHEN** `endSet()` is called with `defaultRestSeconds = 90`
- **THEN** the session emits a tick stream that counts down from 90 to 0

### Requirement: Session 数据快照

After `session.complete()`, the session SHALL expose a `WorkoutSnapshot` value type containing all sets, reps, velocities, peak heart rate, etc. — to be persisted by the storage layer (Proposal 4).

#### Scenario: Snapshot completeness

- **WHEN** a session with 3 sets × 5 reps completes
- **THEN** `snapshot.sets.count == 3`
- **AND** `snapshot.totalReps == 15`
