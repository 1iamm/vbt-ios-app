## ADDED Requirements

### Requirement: LVP 线性回归

`LVPCalculator.fit(setsByLoad:)` SHALL fit `v = a × load + b` via least-squares over distinct loads (≥ 5 required) and return `LVPFit { a, b, r2 }`. Returns nil when fewer than 5 distinct loads.

References: Citations.jidovtseff2011LVP, Citations.garciaRamos2018LVPVariants.

#### Scenario: Insufficient data

- **WHEN** input has 4 distinct loads
- **THEN** result is nil

### Requirement: e1RM 估算

`LVPCalculator.estimate1RM(fit:v1RM:)` SHALL compute `(v1RM - b) / a`. Returns nil when slope `a >= 0` (degenerate).

#### Scenario: Reasonable e1RM

- **WHEN** loads = [60, 70, 80, 90, 100], velocities = [0.85, 0.72, 0.58, 0.45, 0.32], V1RM = 0.30
- **THEN** the estimated 1RM is within ±5% of 100 (since velocity-load is roughly linear)
