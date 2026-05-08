## ADDED Requirements

### Requirement: MetStatus 判定

The system SHALL provide a function `evaluate(velocity: Double, target: ClosedRange<Double>) -> MetStatus` that returns one of `.excellent / .met / .borderline / .failed` per these rules (PRD §M5):

- `excellent` when velocity ≥ target.upperBound
- `met` when target.lowerBound ≤ velocity < target.upperBound
- `borderline` when target.lowerBound × 0.95 ≤ velocity < target.lowerBound (within 5% under)
- `failed` when velocity < target.lowerBound × 0.95

#### Scenario: At upper bound

- **WHEN** velocity = 0.70 and target = 0.55...0.70
- **THEN** result is `.excellent`

#### Scenario: Below 5% margin

- **WHEN** velocity = 0.50 and target = 0.55...0.70
- **THEN** result is `.failed` (50/55 = 0.909, below 0.95)

#### Scenario: Within 5% margin

- **WHEN** velocity = 0.53 and target = 0.55...0.70
- **THEN** result is `.borderline` (53/55 = 0.964, within 5% under)
