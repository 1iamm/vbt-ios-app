## ADDED Requirements

### Requirement: TemplateSnapshot 类型

The system SHALL define `TemplateSnapshot` as a Codable Sendable struct containing: id, name, scheduledDate, items (array of `TemplateItemSnapshot` with exerciseId, targetSets, targetReps, targetWeight, velocityRange, vlCeiling, restSeconds, side).

#### Scenario: Encode round-trip

- **WHEN** a TemplateSnapshot is JSONEncoded then decoded
- **THEN** equality holds

### Requirement: iPhone → Watch 推送

`TemplateSyncService.push(template:on:)` SHALL serialize the TemplateSnapshot for the given date and call `iPhoneConnectivityService` to transferUserInfo (kind = `.template`).

### Requirement: Watch 收到 Template 持久化

The Watch's `WatchConnectivityService` SHALL handle inbound `.template` messages by storing them in `@AppStorage("vbt.todayPlan")` keyed by date.
