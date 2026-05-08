## ADDED Requirements

### Requirement: 共享消息协议

The system SHALL define a `ConnectivityMessage` enum with associated values for each kind:
- `.workoutSnapshot(WorkoutSnapshot)`
- `.jumpTest(JumpTest...)` (Codable equivalent)
- `.template(TemplateSnapshot)` (placeholder; Proposal 9 fills in)

Encoded as `Data` via `JSONEncoder` and tagged with a `kind` string in the userInfo dict.

#### Scenario: Encode / decode round-trip

- **WHEN** a `ConnectivityMessage.workoutSnapshot(s)` is encoded and decoded
- **THEN** the result equals the original

### Requirement: Watch 端 send

`WatchConnectivityService.send(snapshot:)` SHALL queue the snapshot via `WCSession.transferUserInfo` so it survives app backgrounding.

#### Scenario: send returns immediately

- **WHEN** the watch calls `send(snapshot:)`
- **THEN** the call returns within 50ms (delivery is asynchronous)

### Requirement: iPhone 端 receive

`iPhoneConnectivityService` SHALL implement `WCSessionDelegate.session(_:didReceiveUserInfo:)`, decode the message, and on `.workoutSnapshot` call `WorkoutStore.save(...)` against the iPhone's main ModelContainer. After save, post a Foundation `Notification` on `.vbtWorkoutImported`.

#### Scenario: Notification fires after import

- **WHEN** a snapshot arrives via WCSession
- **THEN** `Notification.Name.vbtWorkoutImported` is posted to the default center
