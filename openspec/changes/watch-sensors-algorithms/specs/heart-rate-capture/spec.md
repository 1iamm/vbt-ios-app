## ADDED Requirements

### Requirement: HealthKit 实时心率

The system SHALL provide a `HeartRateManager` that subscribes to `HKAnchoredObjectQuery` for `.heartRate` samples while a workout session is active.

#### Scenario: Subscription emits new samples

- **WHEN** the user's heart rate changes during a workout
- **THEN** `HeartRateManager.stream` emits the new bpm value within 2s

### Requirement: 权限处理

The system SHALL call `HKHealthStore.requestAuthorization` for heart-rate read on first use. If denied, the manager exposes the denial state but continues to function (workout proceeds without heart rate).

#### Scenario: Denial does not crash

- **WHEN** the user denies HealthKit access
- **THEN** `HeartRateManager.start()` does not throw
- **AND** `stream` simply emits no values
