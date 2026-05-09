## ADDED Requirements

### Requirement: Full access request

`EventKitService.requestFullAccess()` SHALL invoke iOS 17+'s `requestFullAccessToEvents` (or pre-17 fallback) and return whether access was granted. The system sheet's body uses `NSCalendarsFullAccessUsageDescription`.

#### Scenario: First reverse-sync enable

- **WHEN** the user toggles 反向读取 on for the first time
- **THEN** the system Calendar full-access sheet appears
- **AND** the toggle reflects the granted/denied state on dismissal

### Requirement: Reverse syncer reconciles ±30 days

`DayPlanReverseSyncer.runReconcile()` SHALL:

- pull all events in the 训练 calendar within [now - 30d, now + 30d]
- look up DayPlans by `eventKitIdentifier`
- update `date` / `scheduledTimeMinutes` when the calendar event's start has drifted
- delete DayPlans whose stored identifier is no longer present (user deleted the event)
- skip DayPlans where `completed == true`
- post `Notification.Name.vbtDayPlanReverseSynced`

#### Scenario: User moves a planned squat from 07:30 to 08:00 in Calendar.app

- **WHEN** the calendar event start changes from 07:30 to 08:00
- **AND** the EKEventStoreChanged notification fires
- **THEN** the matching DayPlan's scheduledTimeMinutes goes from 450 to 480

#### Scenario: User deletes a planned event in Calendar

- **WHEN** the user deletes a 训练 event with identifier "X"
- **AND** runReconcile fires
- **THEN** the DayPlan whose eventKitIdentifier == "X" is deleted

#### Scenario: User completed plan is not auto-edited

- **WHEN** a DayPlan has completed == true and the calendar event's time changed
- **THEN** the DayPlan is NOT modified

### Requirement: App-level subscription

`VBTrainerApp.init` SHALL call `DayPlanReverseSyncer.shared.bind(container:)` once per app launch. The syncer SHALL register a single EKEventStoreChanged observer that triggers `runReconcile()`.

#### Scenario: Each calendar edit triggers reconcile

- **WHEN** the user edits any 训练 event after the syncer is bound and full access granted
- **THEN** runReconcile() is invoked exactly once per change notification

### Requirement: WeeklyPlanView reverse-read toggle

`WeeklyPlanView` SHALL render a "反向读取" toggle row in the sync options card. Toggling on requests full access; if granted, the toggle stays on, runReconcile() executes immediately. The row SHALL include a description: "日历里改时间 / 删除事件 → 计划跟着变".

#### Scenario: Initial toggle reflects authorization

- **WHEN** the WeeklyPlanView appears and `EventKitService.shared.hasReadAccess == true`
- **THEN** the toggle is shown ON

#### Scenario: Denied access returns toggle to off

- **WHEN** the user toggles ON and then denies the system prompt
- **THEN** the toggle reverts to OFF
