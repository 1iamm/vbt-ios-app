## ADDED Requirements

### Requirement: 飞行时间法测高度

The system SHALL provide a `JumpDetector` that, given an IMU sample stream, identifies takeoff and landing events and computes jump height per the flight-time formula:

```
height_meters = g * t_flight^2 / 8
```

Reference: Citations.linthorne2001Jump, Citations.claudino2017CMJ.

#### Scenario: Synthetic 30 cm jump

- **WHEN** a synthetic CMJ signal corresponding to height 0.30 m (flight time ≈ 0.494s) is fed
- **THEN** `JumpDetector.lastJump.heightCm` is 30.0 ± 1.0 cm

### Requirement: 起跳/落地判定

Takeoff is detected when the user is in free-fall (|vertical accel| ≈ 0 ± 1 m/s²); landing when impact spike > 2g occurs after takeoff.

#### Scenario: False landing rejected

- **WHEN** a brief unloading transient (no actual jump) occurs
- **THEN** no jump is recorded (no impact spike follows)

### Requirement: 三次最佳值

`JumpDetector` SHALL accept up to N attempts and report `bestHeightCm = max(attempts)`.

#### Scenario: Best of three

- **WHEN** three jumps of 28, 31, 29 cm are recorded
- **THEN** bestHeightCm = 31.0
