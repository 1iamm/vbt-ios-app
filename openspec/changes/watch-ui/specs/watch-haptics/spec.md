## ADDED Requirements

### Requirement: 4 阶 Rep 震动反馈

The system SHALL provide `HapticFeedback.rep(_:)` that maps `MetStatus` to a haptic pattern:
- `.excellent` → `.success` (double tap)
- `.met` → `.click` (single)
- `.borderline` → `.directionUp` (long single)
- `.failed` → `.failure` (rapid triple)

#### Scenario: All 4 mappings exist

- **WHEN** `HapticFeedback.rep(.excellent)` is called
- **THEN** WKInterfaceDevice receives `.success`

### Requirement: 倒计时结束震动

The system SHALL play `.start` haptic when rest countdown reaches zero.

#### Scenario: Rest end haptic

- **WHEN** `HapticFeedback.restEnded()` is called
- **THEN** WKInterfaceDevice receives `.start`

### Requirement: VL 警戒震动

The system SHALL play `.failure` haptic when VL ceiling is exceeded.

#### Scenario: VL haptic

- **WHEN** `HapticFeedback.vlCeilingExceeded()` is called
- **THEN** WKInterfaceDevice receives `.failure`

### Requirement: 静默时不卡 UI

Haptic calls SHALL be no-ops on non-watchOS platforms (so shared/test code doesn't break) and never throw.

#### Scenario: iOS test environment

- **WHEN** running on iOS simulator
- **THEN** haptic calls succeed without effect
