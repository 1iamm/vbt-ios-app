## ADDED Requirements

### Requirement: Readiness CRUD

The system SHALL provide `ReadinessStore` with `upsert(_:in:)` (key by start-of-day Date) and `latest(in:)`, `forDay(_:in:)`, `recent(days:in:)` accessors.

#### Scenario: Same-day upsert replaces

- **WHEN** two snapshots with the same calendar date are saved
- **THEN** only one row exists in storage (later replaces earlier)
