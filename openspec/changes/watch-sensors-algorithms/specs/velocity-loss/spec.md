## ADDED Requirements

### Requirement: VL% 公式

The system SHALL compute velocity loss percentage per the formula:

```
VL% = (V_first - V_current) / V_first * 100
```

where `V_first` is the velocity of the first rep in the set and `V_current` is the velocity of the current rep, BOTH using the set's configured velocity variant (MV / MPV / PV).

Reference: Citations.sanchezMedina2011VL.

#### Scenario: VL is non-negative and bounded

- **WHEN** rep velocities are [0.62, 0.60, 0.58, 0.55, 0.52, 0.49] m/s
- **THEN** computed VL%s are [0.0, 3.2, 6.5, 11.3, 16.1, 21.0] (each ±0.1)

### Requirement: 实时 VL 流

The system SHALL expose `VelocityLossCalculator.current(after rep:)` that returns the VL% for the latest rep relative to the first rep in the same set.

#### Scenario: Mid-set query

- **WHEN** 3 reps have been recorded with velocities [0.60, 0.55, 0.50]
- **THEN** querying `current(after: rep3)` returns ≈ 16.7%

### Requirement: VL 警戒线触发

The system SHALL provide a function `shouldForceStop(vl: Double, ceiling: Double) -> Bool` that returns true when VL exceeds the configured ceiling. Used by Watch UI to surface the force-stop screen.

#### Scenario: Force-stop above ceiling

- **WHEN** VL is 32% and ceiling is 30%
- **THEN** the function returns true
