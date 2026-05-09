## ADDED Requirements

### Requirement: HealthKit 授权在 app 启动时请求

The system SHALL invoke `HealthKitAuthorization.requestWorkoutAuthorization()` from `VBTrainerWatchApp.init` so that the user is prompted for HealthKit access on first launch (rather than at the moment they tap "Start Workout").

The request SHALL include:
- typesToShare: `HKObjectType.workoutType()`, `HKQuantityType(.activeEnergyBurned)`
- typesToRead: `HKQuantityType(.heartRate)`, `HKQuantityType(.activeEnergyBurned)`, `HKObjectType.workoutType()`

#### Scenario: First launch shows the system prompt

- **WHEN** the user installs and opens the Watch app for the first time
- **THEN** within 1 second of launch the system HealthKit authorization sheet appears
- **AND** the user can grant or deny without any prior interaction with the app

#### Scenario: Subsequent launches do not re-prompt

- **WHEN** the user has already granted (or denied) authorization and opens the app again
- **THEN** no system sheet appears
- **AND** the call returns immediately without throwing

### Requirement: Watch target enables workout-processing background mode

The watchOS target SHALL declare `WKBackgroundModes = ["workout-processing"]` in its Info.plist (via `INFOPLIST_KEY_WKBackgroundModes` in `project.yml`) so that an active `HKWorkoutSession` keeps CoreMotion sampling alive when the wrist drops or the screen times out.

#### Scenario: Background sampling persists when wrist drops

- **WHEN** a session is running and the user lowers the wrist for 30 seconds
- **THEN** on raising the wrist again, the rep counter reflects reps performed during the lowered period (samples were not throttled)

### Requirement: LiveWorkoutController bridges actor events to SwiftUI

The system SHALL provide a `LiveWorkoutController` (`@MainActor final class … : ObservableObject`) that owns one `ActiveWorkoutSession` actor and exposes the following `@Published` mirrors of session events:

- `var rep: Int` — last completed rep index (0 before any rep)
- `var velocity: Double` — last rep's mean velocity in m/s (0 before any rep)
- `var vlPercent: Double` — last rep's velocity-loss % vs first rep of the set (0 before second rep)
- `var heartRate: Int` — most recent heart-rate sample bpm (0 if none received)
- `var metStatus: MetStatus` — last rep's met status (`.met` default)
- `var lastSetSnapshot: SetSnapshot?` — most recently ended set
- `var completedSets: [SetSnapshot]` — accumulated finished sets
- `var isCompleted: Bool` — true after `complete()` resolves
- `var errorMessage: String?` — non-nil if `start()` threw

#### Scenario: Rep event updates published fields

- **WHEN** the underlying session emits `.repCompleted(repEvent, .met)` with `repEvent.index == 3` and `meanVelocity == 0.58`
- **THEN** `controller.rep == 3`
- **AND** `controller.velocity == 0.58`
- **AND** `controller.metStatus == .met`

#### Scenario: Heart-rate event updates published field

- **WHEN** the session emits `.heartRate(142)`
- **THEN** `controller.heartRate == 142`

#### Scenario: Set ended event accumulates snapshot

- **WHEN** the session emits `.setEnded(snapshot)` where `snapshot.index == 1`
- **THEN** `controller.lastSetSnapshot?.index == 1`
- **AND** `controller.completedSets.count == 1`

#### Scenario: Session ended sets isCompleted

- **WHEN** the session emits `.sessionEnded(workoutSnapshot)`
- **THEN** `controller.isCompleted == true`

### Requirement: Controller start failure is exposed, not silent

If the underlying `ActiveWorkoutSession.start(...)` throws (e.g. HealthKit denied, HKWorkoutSession failed), `LiveWorkoutController.start(...)` SHALL catch the error, set `errorMessage` to a user-facing description, and NOT propagate further. The view can then render an inline error.

#### Scenario: Authorization denied surfaces error

- **WHEN** `start()` is called and `MotionManager.start()` throws `.workoutSessionFailed(...)`
- **THEN** `controller.errorMessage` is non-nil
- **AND** `controller.isCompleted` is false (session never started)
- **AND** no fatal trap occurs

### Requirement: WatchLiveWorkoutView consumes the controller

`WatchLiveWorkoutView` SHALL:
- own a `@StateObject var controller = LiveWorkoutController()`
- expose `controller` to descendant views via `.environmentObject(controller)`
- call `controller.start(exerciseId:, weightKg:, ...)` from a `.task` modifier on first appearance
- bind every numeric / status display to `controller.<published>` (no `@State` defaults like `rep = 5`)
- on the "结束本组" button, dispatch `Task { await controller.endSet() }` then push `.rest(...)`

#### Scenario: View renders live data

- **WHEN** the view appears with `exerciseId = "back-squat"`, `weightKg = 100`
- **THEN** `controller.start(...)` is invoked
- **AND** the `Rep N` and velocity texts read from `controller.rep` and `controller.velocity` (not constants)

#### Scenario: End-set transitions session and pushes rest

- **WHEN** the user taps "结束本组"
- **THEN** `controller.endSet()` is awaited
- **AND** the navigation pushes `.rest(secondsRemaining: <session default>)`

### Requirement: WatchSummaryView completes session and syncs to iPhone

`WatchSummaryView` SHALL:
- read `controller` from `@EnvironmentObject`
- display `totalReps`, `avgVelocity`, `avgVL`, `avgHR` computed from `controller.completedSets` (no hard-coded init parameters)
- on the "完成" button, dispatch:
  ```
  Task {
      let snap = await controller.complete()
      WatchConnectivityService.shared.send(message: .workoutSnapshot(snap))
      nav.popToRoot()
  }
  ```

#### Scenario: Done button sends snapshot then resets nav

- **WHEN** the user taps "完成"
- **THEN** `controller.complete()` is awaited and returns a `WorkoutSnapshot`
- **AND** `WatchConnectivityService.shared.send(message: .workoutSnapshot(snap))` is called exactly once
- **AND** the navigation resets to root

#### Scenario: Snapshot reaches iPhone for persistence

- **WHEN** the iPhone app is reachable (foreground or background) and the snapshot is sent
- **THEN** within ~10s `iPhoneConnectivityService.didReceiveUserInfo` decodes the snapshot
- **AND** `WorkoutStore.save(snap, in: context)` writes a `Workout` with all `WorkoutSet`s and `Rep`s
- **AND** `NotificationCenter` posts `.vbtWorkoutImported` so iOS Today / History views refresh

### Requirement: Session is released if the view leaves without completing

If the user navigates away from `WatchLiveWorkoutView` without going through `endSet()` → `complete()` (e.g. force-pop via Digital Crown long-press), `LiveWorkoutController.cancel()` SHALL be called from `.onDisappear` to:
- cancel the session-event consumer task
- call `await session.complete()` and discard the snapshot (this stops `MotionManager` and `HeartRateManager`, ending the `HKWorkoutSession`)

The cancel SHALL be skipped when the disappear is caused by pushing to a child screen (Rest / Summary), so the session continues across the nav stack.

#### Scenario: Force-pop releases sensors

- **WHEN** the user is in Live Workout and force-pops back to root (no end-set, no complete)
- **THEN** within 500 ms the underlying `HKWorkoutSession` is in `.ended` state
- **AND** `MotionManager.isRunning == false`

#### Scenario: Push to Rest does not cancel

- **WHEN** the user taps "结束本组" and the nav pushes `.rest`
- **THEN** the controller's session is NOT cancelled (it is in `.resting`, not `.completed`)
- **AND** subsequent `startNextSet(...)` works
