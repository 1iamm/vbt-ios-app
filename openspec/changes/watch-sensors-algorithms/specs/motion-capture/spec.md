## ADDED Requirements

### Requirement: 100Hz IMU 采集

The system SHALL provide a `MotionManager` actor on watchOS that streams `MotionSample` values at 100 Hz from `CMMotionManager.startDeviceMotionUpdates`. Each `MotionSample` contains a monotonic timestamp, a `userAcceleration` vector (gravity-compensated, in m/s²), and the attitude quaternion.

#### Scenario: Stream emits at expected rate

- **WHEN** `MotionManager.start()` is called and the manager runs for 1 second
- **THEN** the stream emits between 95 and 105 samples (allowing for system jitter)

### Requirement: HKWorkoutSession 防降频

The system SHALL open an `HKWorkoutSession` with `activityType = .traditionalStrengthTraining` BEFORE starting CMMotion updates. This prevents watchOS from throttling the sample rate when the wrist drops.

#### Scenario: Workout session active during motion capture

- **WHEN** `MotionManager.start()` is invoked
- **THEN** an `HKWorkoutSession` is in `.running` state
- **AND** `motionManager.deviceMotionUpdateInterval` is `1.0 / 100.0`

### Requirement: 强引用 CMMotionManager

`MotionManager` SHALL hold its `CMMotionManager` instance as a stored property (strong reference). Allocating it as a local in `start()` would let ARC release it and break sampling.

#### Scenario: Manager survives across the start call

- **WHEN** `MotionManager.start()` returns
- **THEN** the underlying `CMMotionManager` is still alive (a private property)

### Requirement: 优雅停止

`MotionManager.stop()` SHALL stop motion updates, end the workout session, and complete the AsyncStream cleanly.

#### Scenario: Stop terminates the stream

- **WHEN** `MotionManager.stop()` is called while the stream has an active iterator
- **THEN** the iterator's next `for await` returns `nil` within 200ms
- **AND** subsequent `start()` works again
