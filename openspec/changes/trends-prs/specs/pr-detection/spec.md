## ADDED Requirements

### Requirement: 自动 PR 检测

The system SHALL provide `PersonalRecordDetector.checkAndRecord(snapshot:in:)` that, given a freshly-saved Workout, detects whether any of the following PR kinds are beaten and inserts a `PersonalRecord` row:
- `.maxWeight` — heaviest single rep
- `.maxVolume` — total kg·reps
- `.maxSingleRepVelocity` — fastest single rep velocity
- `.e1RM` — only if LVP is computable

#### Scenario: New maxWeight PR

- **WHEN** a workout has a heavier rep than any prior `.maxWeight` PR for the same exercise
- **THEN** a new `PersonalRecord` is inserted with kind `.maxWeight`
