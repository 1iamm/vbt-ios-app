## ADDED Requirements

### Requirement: 梯形积分速度

The system SHALL compute vertical velocity by trapezoidal integration of `userAcceleration.z`:

```
v[t+1] = v[t] + (a[t] + a[t+1]) / 2 * dt
```

#### Scenario: Constant acceleration produces linear velocity

- **WHEN** a constant a=1 m/s² signal is integrated over 1s at 100Hz
- **THEN** the final velocity is within ±0.01 m/s of 1.0 m/s

### Requirement: ZUPT 校正

The velocity integrator SHALL accept ZUPT trigger calls (from RepDetector) that hard-reset velocity to 0.

#### Scenario: ZUPT zeroes the integrator

- **WHEN** velocity is 0.42 m/s and `applyZUPT()` is called
- **THEN** subsequent reads return 0.0 until next integration step

### Requirement: MV / PV / MPV 计算

For each rep, the system SHALL compute three velocity variants:
- `meanVelocity` (MV): time-averaged absolute velocity over the concentric phase
- `peakVelocity` (PV): max of velocity over the concentric phase
- `meanPropulsiveVelocity` (MPV): time-averaged velocity over the propulsive sub-phase (samples where acceleration > 0 within concentric)

#### Scenario: Synthetic concentric profile

- **WHEN** a synthetic concentric phase is generated with a known velocity profile (peak 0.7 m/s, mean 0.5 m/s, propulsive mean 0.55 m/s)
- **THEN** `RepEvent.peakVelocity ≈ 0.7`, `meanVelocity ≈ 0.5`, `meanPropulsiveVelocity ≈ 0.55` (each within ±5%)

### Requirement: Concentric 阶段识别

The system SHALL identify the concentric phase as the period from `bottom` exit to `top` entry in the rep state machine.

#### Scenario: Concentric duration matches signal

- **WHEN** a synthetic rep with concentric duration 0.8s is fed
- **THEN** the computed concentric duration is 0.8s ± 50ms
