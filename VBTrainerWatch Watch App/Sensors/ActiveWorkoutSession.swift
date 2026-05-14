// ActiveWorkoutSession.swift
// VBTrainer · watchOS · 2026-05
//
// High-level session orchestrator: composes MotionManager + HeartRateManager
// + RepDetector + VelocityLossCalculator into a single API the UI drives.

import Foundation

@available(watchOS 10.0, *)
public actor ActiveWorkoutSession {
    public enum SessionState: Sendable, Equatable {
        case idle
        case running(setIndex: Int)
        case resting(secondsRemaining: Int)
        case completed
    }

    public enum SessionEvent: Sendable {
        case stateChanged(SessionState)
        case repCompleted(RepEvent, MetStatus)
        case heartRate(Int)
        case vlCeilingExceeded(currentVL: Double, ceiling: Double)
        case restTick(secondsRemaining: Int)
        case setEnded(SetSnapshot)
        case sessionEnded(WorkoutSnapshot)
    }

    public private(set) var state: SessionState = .idle

    public var events: AsyncStream<SessionEvent> {
        _events
    }

    private let _events: AsyncStream<SessionEvent>
    private let eventCont: AsyncStream<SessionEvent>.Continuation

    private let motionManager = MotionManager()
    private let heartRateManager = HeartRateManager()
    private let repDetector = RepDetector()
    private var vlCalc: VelocityLossCalculator?

    private var exerciseId: String = ""
    private var defaultRestSeconds: Int = 90

    private var currentSetIndex: Int = 0
    private var currentSet: SetSnapshot?
    private var allSets: [SetSnapshot] = []
    private var heartRateSamples: [HeartRateSample] = []
    private var sessionStart: Date = .init()

    private var motionTask: Task<Void, Never>?
    private var heartRateTask: Task<Void, Never>?
    private var restTask: Task<Void, Never>?

    public init() {
        var c: AsyncStream<SessionEvent>.Continuation!
        _events = AsyncStream { c = $0 }
        eventCont = c
    }

    // MARK: - Public API

    public func start(
        exerciseId: String,
        weightKg: Double,
        velocityVariant: VelocityVariant,
        targetRange: ClosedRange<Double>?,
        vlCeiling: Double?,
        side: Side,
        defaultRestSeconds: Int
    ) async throws {
        guard case .idle = state else { return }
        self.exerciseId = exerciseId
        self.defaultRestSeconds = defaultRestSeconds
        sessionStart = Date()
        allSets.removeAll()
        currentSetIndex = 0

        try await beginNextSet(
            weightKg: weightKg,
            velocityVariant: velocityVariant,
            targetRange: targetRange,
            vlCeiling: vlCeiling,
            side: side
        )
    }

    public func endSet() async {
        guard case .running = state, let set = currentSet else { return }
        let finalized = set
        allSets.append(finalized)
        eventCont.yield(.setEnded(finalized))
        currentSet = nil
        await transition(.resting(secondsRemaining: defaultRestSeconds))
        startRestCountdown(from: defaultRestSeconds)
    }

    public func startNextSet(
        weightKg: Double,
        velocityVariant: VelocityVariant,
        targetRange: ClosedRange<Double>?,
        vlCeiling: Double?,
        side: Side
    ) async throws {
        cancelRest()
        try await beginNextSet(
            weightKg: weightKg,
            velocityVariant: velocityVariant,
            targetRange: targetRange,
            vlCeiling: vlCeiling,
            side: side
        )
    }

    public func complete() async -> WorkoutSnapshot {
        // Auto-finalize a still-open set.
        if let set = currentSet {
            allSets.append(set)
            eventCont.yield(.setEnded(set))
            currentSet = nil
        }
        await stopSensors()
        cancelRest()
        let snapshot = WorkoutSnapshot(
            exerciseId: exerciseId,
            startedAt: sessionStart,
            endedAt: Date(),
            sets: allSets,
            heartRateSamples: heartRateSamples
        )
        await transition(.completed)
        eventCont.yield(.sessionEnded(snapshot))
        eventCont.finish()
        return snapshot
    }

    // MARK: - Internals

    private func beginNextSet(
        weightKg: Double,
        velocityVariant: VelocityVariant,
        targetRange: ClosedRange<Double>?,
        vlCeiling: Double?,
        side: Side
    ) async throws {
        currentSetIndex += 1
        let snapshot = SetSnapshot(
            index: currentSetIndex,
            weightKg: weightKg,
            velocityVariant: velocityVariant,
            targetRange: targetRange,
            vlCeiling: vlCeiling,
            side: side,
            restAfterSeconds: defaultRestSeconds
        )
        currentSet = snapshot
        vlCalc = VelocityLossCalculator(variant: velocityVariant)

        configureRepDetector(targetRange: targetRange, vlCeiling: vlCeiling)

        if currentSetIndex == 1 {
            try await motionManager.start()
            await heartRateManager.start()
            startConsumers()
        } else {
            repDetector.reset()
        }
        await transition(.running(setIndex: currentSetIndex))
    }

    private func configureRepDetector(
        targetRange: ClosedRange<Double>?,
        vlCeiling: Double?
    ) {
        repDetector.onRepCompleted = { [weak self] rep in
            guard let self else { return }
            Task { await self.handleRep(rep, target: targetRange, vlCeiling: vlCeiling) }
        }
    }

    private func handleRep(
        _ rep: RepEvent,
        target: ClosedRange<Double>?,
        vlCeiling: Double?
    ) async {
        guard var set = currentSet, var vlCalc else { return }
        let variant = set.velocityVariant
        let velocity = rep.velocity(for: variant)

        let metStatus: MetStatus = if let target {
            MetStatusEvaluator.evaluate(velocity: velocity, target: target)
        } else {
            .met
        }

        let snapshot = RepSnapshot(
            index: rep.index,
            meanVelocity: rep.meanVelocity,
            peakVelocity: rep.peakVelocity,
            meanPropulsiveVelocity: rep.meanPropulsiveVelocity,
            timestamp: Date(),
            metStatus: metStatus
        )
        set.reps.append(snapshot)
        currentSet = set

        vlCalc.record(rep: rep)
        self.vlCalc = vlCalc

        eventCont.yield(.repCompleted(rep, metStatus))

        if let ceiling = vlCeiling {
            let vl = vlCalc.velocityLoss(for: rep)
            if VelocityLossPolicy.shouldForceStop(vl: vl, ceiling: ceiling) {
                eventCont.yield(.vlCeilingExceeded(currentVL: vl, ceiling: ceiling))
            }
        }
    }

    private func startConsumers() {
        motionTask = Task.detached { [weak self] in
            guard let self else { return }
            for await sample in await motionManager.stream {
                await repDetector.ingest(sample)
            }
        }
        heartRateTask = Task.detached { [weak self] in
            guard let self else { return }
            for await bpm in await heartRateManager.stream {
                await appendHeartRate(bpm)
            }
        }
    }

    private func appendHeartRate(_ bpm: Int) {
        heartRateSamples.append(.init(timestamp: Date(), bpm: bpm))
        eventCont.yield(.heartRate(bpm))
    }

    private func startRestCountdown(from seconds: Int) {
        cancelRest()
        restTask = Task { [weak self] in
            guard let self else { return }
            for remaining in stride(from: seconds, through: 0, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await tickRest(remaining)
            }
        }
    }

    private func tickRest(_ remaining: Int) async {
        guard case .resting = state else { return }
        await transition(.resting(secondsRemaining: remaining))
        eventCont.yield(.restTick(secondsRemaining: remaining))
    }

    private func cancelRest() {
        restTask?.cancel()
        restTask = nil
    }

    private func stopSensors() async {
        motionTask?.cancel(); motionTask = nil
        heartRateTask?.cancel(); heartRateTask = nil
        await motionManager.stop()
        await heartRateManager.stop()
    }

    private func transition(_ newState: SessionState) async {
        state = newState
        eventCont.yield(.stateChanged(newState))
    }
}
