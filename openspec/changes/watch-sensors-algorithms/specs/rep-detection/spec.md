## ADDED Requirements

### Requirement: 状态机 Rep 识别

The system SHALL provide a `RepDetector` that consumes `MotionSample` values and emits a `RepEvent` whenever a complete rep cycle is detected. The state machine has 5 states: `rest / eccentric / bottom / concentric / top`.

#### Scenario: Synthetic clean reps detected exactly

- **WHEN** a synthetic signal of 5 clean reps (peak vertical velocity ~0.6 m/s, separated by 1s rests) is fed
- **THEN** `RepDetector` emits exactly 5 `RepEvent`s
- **AND** each event's `peakVelocity` is within ±5% of the synthetic peak

#### Scenario: Static input emits no reps

- **WHEN** a 10s static signal (zero acceleration, only noise σ=0.05 m/s²) is fed
- **THEN** zero `RepEvent`s are emitted

### Requirement: 状态停留时长阈值

Each non-`rest` state SHALL require a minimum dwell time before transitioning, to filter signal noise. Defaults: eccentric ≥ 200ms, concentric ≥ 200ms, top ≥ 100ms, bottom ≥ 50ms.

#### Scenario: Sub-threshold transient ignored

- **WHEN** an instantaneous spike of 3g for 50ms is injected during rest
- **THEN** no rep is emitted

### Requirement: ZUPT 校正点

When the state machine enters `rest`, the velocity integrator SHALL be reset to 0 to prevent drift from accumulating across reps.

#### Scenario: Drift bounded across long set

- **WHEN** 30 consecutive reps are simulated with 100µs of integrator drift per rep
- **THEN** the velocity error at rep 30 is ≤ 0.10 m/s (bounded by ZUPT, not 30× drift)
