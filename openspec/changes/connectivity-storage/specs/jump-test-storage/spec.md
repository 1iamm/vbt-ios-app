## ADDED Requirements

### Requirement: JumpTest CRUD

The system SHALL provide `JumpTestStore` with `save(attempts:in:) -> JumpTest`, `latest(in:) -> JumpTest?`, `recent(within:in:) -> [JumpTest]` methods.

#### Scenario: Save attempts

- **WHEN** `save(attempts: [28, 31, 29], in: context)` is called
- **THEN** a `JumpTest` is persisted with `bestHeightCm == 31`
