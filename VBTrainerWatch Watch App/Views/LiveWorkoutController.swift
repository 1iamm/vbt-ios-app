// LiveWorkoutController.swift
// VBTrainer · watchOS · 2026-05
//
// SwiftUI bridge from the ActiveWorkoutSession actor (and its AsyncStream of
// SessionEvents) to @Published fields the Live Workout UI binds to.
//
// Owned by WatchRootView via @StateObject and shared with Live / Rest /
// Summary via .environmentObject. Reused across workouts — `start()` rebuilds
// the underlying actor.

import Foundation
import SwiftUI

@available(watchOS 10.0, *)
@MainActor
public final class LiveWorkoutController: ObservableObject {

    // MARK: - Published mirrors of session state

    @Published public private(set) var rep: Int = 0
    @Published public private(set) var velocity: Double = 0
    @Published public private(set) var vlPercent: Double = 0
    @Published public private(set) var heartRate: Int = 0
    @Published public private(set) var metStatus: MetStatus = .met

    @Published public private(set) var lastSetSnapshot: SetSnapshot?
    @Published public private(set) var completedSets: [SetSnapshot] = []
    @Published public private(set) var heartRateSamples: [HeartRateSample] = []

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var isCompleted: Bool = false
    @Published public private(set) var errorMessage: String?

    /// Snapshot returned by `complete()` — cached so Summary can render.
    public private(set) var finishedSnapshot: WorkoutSnapshot?

    /// Captured from the last `start(...)` call so the Rest screen's "下一组"
    /// button can invoke `startNextSet()` without needing to re-route weight.
    public private(set) var currentExerciseId: String = ""
    public private(set) var currentWeightKg: Double = 0
    public private(set) var currentVelocityVariant: VelocityVariant = .mv
    public private(set) var currentTargetRange: ClosedRange<Double>?
    public private(set) var currentVLCeiling: Double?
    public private(set) var currentSide: Side = .both

    // MARK: - Internal

    private var session = ActiveWorkoutSession()
    private var consumerTask: Task<Void, Never>?

    /// First-rep velocity within the current set, used to compute live VL%.
    private var setBaselineVelocity: Double?

    public init() {}

    // MARK: - Lifecycle

    public func start(
        exerciseId: String,
        weightKg: Double,
        velocityVariant: VelocityVariant = .mv,
        targetRange: ClosedRange<Double>? = nil,
        vlCeiling: Double? = nil,
        side: Side = .both,
        defaultRestSeconds: Int = 90
    ) async {
        // Idempotent: if already running this workout, no-op.
        if isRunning { return }
        // Fresh start: rebuild session and reset all mirrors.
        resetForNewWorkout()
        currentExerciseId = exerciseId
        currentWeightKg = weightKg
        currentVelocityVariant = velocityVariant
        currentTargetRange = targetRange
        currentVLCeiling = vlCeiling
        currentSide = side
        let stream = await session.events
        consumerTask = Task { [weak self] in
            for await event in stream {
                await self?.apply(event)
            }
        }
        do {
            try await session.start(
                exerciseId: exerciseId,
                weightKg: weightKg,
                velocityVariant: velocityVariant,
                targetRange: targetRange,
                vlCeiling: vlCeiling,
                side: side,
                defaultRestSeconds: defaultRestSeconds
            )
            isRunning = true
        } catch {
            errorMessage = "训练开始失败：\(error.localizedDescription)"
            consumerTask?.cancel()
            consumerTask = nil
        }
    }

    public func endSet() async {
        guard isRunning else { return }
        await session.endSet()
    }

    public func startNextSet(
        weightKg: Double,
        velocityVariant: VelocityVariant = .mv,
        targetRange: ClosedRange<Double>? = nil,
        vlCeiling: Double? = nil,
        side: Side = .both
    ) async {
        do {
            try await session.startNextSet(
                weightKg: weightKg,
                velocityVariant: velocityVariant,
                targetRange: targetRange,
                vlCeiling: vlCeiling,
                side: side
            )
            setBaselineVelocity = nil
        } catch {
            errorMessage = "下一组启动失败：\(error.localizedDescription)"
        }
    }

    @discardableResult
    public func complete() async -> WorkoutSnapshot {
        let snapshot = await session.complete()
        finishedSnapshot = snapshot
        isCompleted = true
        isRunning = false
        consumerTask?.cancel()
        consumerTask = nil
        return snapshot
    }

    /// Force release of sensors when the view leaves without completing.
    public func cancel() async {
        guard isRunning else { return }
        _ = await session.complete()
        isRunning = false
        isCompleted = true
        consumerTask?.cancel()
        consumerTask = nil
    }

    // MARK: - Event application (visible for tests)

    public func apply(_ event: ActiveWorkoutSession.SessionEvent) {
        switch event {
        case .repCompleted(let repEvent, let status):
            rep = repEvent.index
            velocity = repEvent.meanVelocity
            metStatus = status
            if setBaselineVelocity == nil {
                setBaselineVelocity = repEvent.meanVelocity
                vlPercent = 0
            } else if let baseline = setBaselineVelocity, baseline > 0 {
                vlPercent = max(0, (baseline - repEvent.meanVelocity) / baseline * 100)
            }

        case .heartRate(let bpm):
            heartRate = bpm
            heartRateSamples.append(.init(timestamp: Date(), bpm: bpm))

        case .setEnded(let snapshot):
            lastSetSnapshot = snapshot
            completedSets.append(snapshot)
            setBaselineVelocity = nil
            vlPercent = 0

        case .sessionEnded(let snapshot):
            finishedSnapshot = snapshot
            isCompleted = true
            isRunning = false

        case .stateChanged, .vlCeilingExceeded, .restTick:
            break
        }
    }

    // MARK: - Aggregates for Summary

    public var totalReps: Int {
        completedSets.reduce(0) { $0 + $1.reps.count }
    }

    public var avgVelocity: Double {
        let all = completedSets.flatMap { $0.reps }
        guard !all.isEmpty else { return 0 }
        return all.map(\.meanVelocity).reduce(0, +) / Double(all.count)
    }

    /// Mean of per-set last-rep VL% (final VL of each set, averaged).
    public var avgVLPercent: Int {
        let perSet: [Double] = completedSets.compactMap { set in
            guard let first = set.reps.first?.meanVelocity, first > 0,
                  let last = set.reps.last?.meanVelocity else { return nil }
            return max(0, (first - last) / first * 100)
        }
        guard !perSet.isEmpty else { return 0 }
        return Int((perSet.reduce(0, +) / Double(perSet.count)).rounded())
    }

    public var avgHeartRate: Int {
        guard !heartRateSamples.isEmpty else { return 0 }
        return heartRateSamples.map(\.bpm).reduce(0, +) / heartRateSamples.count
    }

    // MARK: - Private

    private func resetForNewWorkout() {
        rep = 0
        velocity = 0
        vlPercent = 0
        heartRate = 0
        metStatus = .met
        lastSetSnapshot = nil
        completedSets = []
        heartRateSamples = []
        isCompleted = false
        errorMessage = nil
        finishedSnapshot = nil
        setBaselineVelocity = nil
        consumerTask?.cancel()
        consumerTask = nil
        // The actor's events stream is finished after complete(); rebuild.
        session = ActiveWorkoutSession()
    }

    deinit {
        consumerTask?.cancel()
    }
}
