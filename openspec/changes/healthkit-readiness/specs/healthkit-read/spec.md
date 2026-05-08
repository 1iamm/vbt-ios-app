## ADDED Requirements

### Requirement: HealthKit 异步读取

The system SHALL provide a `HealthKitService` (actor) with these async methods:
- `latestSleep(within: Double) async -> (totalHours: Double?, deep: Double?, rem: Double?)`
- `latestHRV() async -> Double?`
- `latestRestingHR() async -> Int?`
- `latestWristTemperature() async -> Double?`
- `latestRespiratoryRate() async -> Double?`
- `recentSamples(_ identifier: HKQuantityTypeIdentifier, days: Int) async -> [Double]`

Each method gracefully returns nil/empty when permission is denied or data unavailable.

#### Scenario: Permission denied returns nil

- **WHEN** the user has denied HealthKit
- **THEN** all latest* methods return nil rather than throwing

### Requirement: 平台 guard

When compiled for non-iOS / non-watchOS platforms or when HealthKit isn't available, all methods SHALL return nil/empty without crashing.
