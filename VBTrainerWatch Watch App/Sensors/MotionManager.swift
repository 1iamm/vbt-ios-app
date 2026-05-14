// MotionManager.swift
// VBTrainer · watchOS · 2026-05
//
// 100Hz IMU capture wrapped behind an HKWorkoutSession to prevent
// throttling. Exposes MotionSamples as an AsyncStream.
//
// References:
//   - Citations.balshaw2023AppleWatch (Apple Watch wrist VBT validation)
//
// IMPORTANT: CMMotionManager must be a stored property; otherwise ARC
// releases it after start() returns and motion updates silently die.

import Foundation
import simd

#if canImport(CoreMotion)
    import CoreMotion
#endif

#if canImport(HealthKit)
    import HealthKit
#endif

@available(watchOS 10.0, *)
public actor MotionManager {
    public enum MotionError: LocalizedError {
        case deviceMotionUnavailable
        case alreadyRunning
        case workoutSessionFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .deviceMotionUnavailable:
                "设备运动数据不可用（模拟器或权限被拒）"
            case .alreadyRunning:
                "传感器已在运行中"
            case let .workoutSessionFailed(underlying):
                "HKWorkoutSession 启动失败：\(underlying.localizedDescription)"
            }
        }
    }

    /// Reference: Citations.balshaw2023AppleWatch — 100 Hz is sufficient and
    /// achievable on Series 7+ when an HKWorkoutSession is active.
    public static let sampleHz: Double = 100

    public private(set) var isRunning = false

    public var stream: AsyncStream<MotionSample> {
        _stream
    }

    // MARK: - Private state

    #if canImport(CoreMotion)
        private let motionManager = CMMotionManager()
    #endif

    #if canImport(HealthKit)
        private let healthStore = HKHealthStore()
        private var workoutSession: HKWorkoutSession?
        private var workoutBuilder: HKLiveWorkoutBuilder?
    #endif

    private var continuation: AsyncStream<MotionSample>.Continuation?
    private let _stream: AsyncStream<MotionSample>

    public init() {
        var continuation: AsyncStream<MotionSample>.Continuation!
        _stream = AsyncStream { c in continuation = c }
        // Capturing continuation must happen after init since actors can't
        // assign self.* in the constructor closure cleanly across versions.
        self.continuation = continuation
    }

    // MARK: - Public API

    public func start() async throws {
        // Idempotent: if a previous start already brought sensors up (e.g.
        // an actor-reentrant call from controller start + LiveSet .task,
        // or a stale instance still alive in simulator hot-reload), don't
        // throw — just no-op so the UI doesn't show a misleading 「训练
        // 开始失败」when data IS actually flowing.
        if isRunning {
            #if DEBUG
                print("[MM] start() called when already running — ignoring")
            #endif
            return
        }
        #if canImport(CoreMotion) && canImport(HealthKit)
            guard motionManager.isDeviceMotionAvailable else {
                throw MotionError.deviceMotionUnavailable
            }

            try await startWorkoutSession()
            startMotionUpdates()
            isRunning = true
        #else
            // Build for non-watch platforms: no-op (lets shared code compile).
            isRunning = true
        #endif
    }

    public func stop() async {
        guard isRunning else { return }
        #if canImport(CoreMotion)
            motionManager.stopDeviceMotionUpdates()
        #endif
        #if canImport(HealthKit)
            await endWorkoutSession()
        #endif
        continuation?.finish()
        isRunning = false
    }

    // MARK: - HKWorkoutSession

    #if canImport(HealthKit)
        private func startWorkoutSession() async throws {
            let config = HKWorkoutConfiguration()
            config.activityType = .traditionalStrengthTraining
            config.locationType = .indoor

            do {
                #if os(watchOS)
                    let session = try HKWorkoutSession(
                        healthStore: healthStore,
                        configuration: config
                    )
                    let builder = session.associatedWorkoutBuilder()
                    builder.dataSource = HKLiveWorkoutDataSource(
                        healthStore: healthStore,
                        workoutConfiguration: config
                    )
                    session.startActivity(with: Date())
                    try await builder.beginCollection(at: Date())
                    workoutSession = session
                    workoutBuilder = builder
                #endif
            } catch {
                throw MotionError.workoutSessionFailed(error)
            }
        }

        private func endWorkoutSession() async {
            #if os(watchOS)
                workoutSession?.end()
                try? await workoutBuilder?.endCollection(at: Date())
                try? await workoutBuilder?.finishWorkout()
            #endif
            workoutSession = nil
            workoutBuilder = nil
        }
    #endif

    // MARK: - CMDeviceMotion

    #if canImport(CoreMotion)
        private func startMotionUpdates() {
            motionManager.deviceMotionUpdateInterval = 1.0 / Self.sampleHz
            // We only need user acceleration (gravity-removed) + attitude — no need
            // for magnetometer (battery, accuracy near steel plates is bad).
            let queue = OperationQueue()
            queue.qualityOfService = .userInteractive
            queue.maxConcurrentOperationCount = 1

            motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
                guard let self, let m = motion else { return }
                // Convert g → m/s² (CoreMotion delivers userAcceleration in g).
                let g = 9.80665
                let accel = SIMD3<Double>(
                    m.userAcceleration.x * g,
                    m.userAcceleration.y * g,
                    m.userAcceleration.z * g
                )
                let q = simd_quatd(
                    ix: m.attitude.quaternion.x,
                    iy: m.attitude.quaternion.y,
                    iz: m.attitude.quaternion.z,
                    r: m.attitude.quaternion.w
                )
                let sample = MotionSample(
                    timestamp: m.timestamp,
                    userAccel: accel,
                    attitude: q
                )
                Task { await self.yield(sample) }
            }
        }
    #endif

    private func yield(_ sample: MotionSample) {
        continuation?.yield(sample)
    }
}
