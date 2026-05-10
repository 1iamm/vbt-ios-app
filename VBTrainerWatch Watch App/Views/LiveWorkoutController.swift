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

    /// Per-set specs from the iPhone-side plan. When non-empty, each set's
    /// weight/reps/rest are pulled from `plannedSpecs[plannedSetCursor]`
    /// instead of repeating `currentWeightKg`.
    public private(set) var plannedSpecs: [TemplateSetSpecSnapshot] = []
    public private(set) var plannedSetCursor: Int = 0  // 0-based index into plannedSpecs

    /// V2 resume support: the TemplateItem the controller is currently working
    /// on, persisted alongside `plannedSpecs` / `plannedSetCursor` so a
    /// killed-and-restarted Watch app can pick up where it left off.
    public private(set) var currentTemplateItemId: UUID?

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
        // Fresh start: rebuild session and reset all mirrors. preparePlanned()
        // may have already populated currentTargetRange / currentVLCeiling /
        // currentExerciseId before this call — keep those when a plan is loaded.
        resetForNewWorkout()
        let usingPlan = !plannedSpecs.isEmpty
        currentExerciseId = usingPlan ? currentExerciseId : exerciseId
        currentWeightKg = usingPlan ? (plannedSpecs.first?.weightKg ?? weightKg) : weightKg
        currentVelocityVariant = velocityVariant
        currentTargetRange = usingPlan ? (currentTargetRange ?? targetRange) : targetRange
        currentVLCeiling = usingPlan ? (currentVLCeiling ?? vlCeiling) : vlCeiling
        currentSide = side
        if usingPlan, let firstRest = plannedSpecs.first?.restSeconds {
            lastResolvedRest = firstRest
        }
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
        plannedSetCursor += 1
        persistResumeCursor()
        HapticFeedback.setEnded()
    }

    /// Inspect the next planned set's parameters (used by Rest screen to
    /// auto-fill the "下一组" button). Returns nil when no plan or finished.
    public var nextPlannedParams: (weightKg: Double, reps: Int, rest: Int, isWarmUp: Bool)? {
        guard !plannedSpecs.isEmpty, plannedSetCursor < plannedSpecs.count else { return nil }
        let s = plannedSpecs[plannedSetCursor]
        return (s.weightKg, s.reps, s.restSeconds, s.kindRaw == "warmUp")
    }

    /// Start the next set. When a plan is loaded, params come from
    /// `plannedSpecs[plannedSetCursor]`; otherwise the caller's args are used.
    public func startNextSet(
        weightKg: Double? = nil,
        velocityVariant: VelocityVariant? = nil,
        targetRange: ClosedRange<Double>? = nil,
        vlCeiling: Double? = nil,
        side: Side? = nil
    ) async {
        let resolvedWeight: Double
        let resolvedRest: Int?
        if let next = nextPlannedParams {
            resolvedWeight = next.weightKg
            resolvedRest = next.rest
        } else {
            resolvedWeight = weightKg ?? currentWeightKg
            resolvedRest = nil
        }
        do {
            try await session.startNextSet(
                weightKg: resolvedWeight,
                velocityVariant: velocityVariant ?? currentVelocityVariant,
                targetRange: targetRange ?? currentTargetRange,
                vlCeiling: vlCeiling ?? currentVLCeiling,
                side: side ?? currentSide
            )
            currentWeightKg = resolvedWeight
            if let r = resolvedRest {
                // store rest for UI (RestView reads it for countdown)
                lastResolvedRest = r
            }
            setBaselineVelocity = nil
        } catch {
            errorMessage = "下一组启动失败：\(error.localizedDescription)"
        }
    }

    /// Most recent set's planned rest seconds (used by RestView countdown).
    public private(set) var lastResolvedRest: Int = 90

    /// Public alias of `lastResolvedRest` for V2 view consumers.
    public var currentRestSeconds: Int { lastResolvedRest }

    /// Summary of the most recently completed set, derived from
    /// `completedSets.last`. V2 SetResult screen reads this to render the
    /// 3-state judgement (excellent / met / borderline / failed).
    public var lastSetMetSummary: (status: MetStatus, mv: Double, target: ClosedRange<Double>?)? {
        guard let last = completedSets.last, !last.reps.isEmpty else { return nil }
        let mv = last.reps.map(\.meanVelocity).reduce(0, +) / Double(last.reps.count)
        let status: MetStatus
        if let range = currentTargetRange {
            status = MetStatusEvaluator.evaluate(velocity: mv, target: range)
        } else {
            status = .met
        }
        return (status, mv, currentTargetRange)
    }

    /// Prepare the controller for a planned multi-set item (called before
    /// pushing the LiveWorkout route). After this, `start(...)` will use
    /// the first spec's params.
    public func preparePlanned(item: TemplateItemSnapshot) {
        plannedSpecs = item.setSpecs.sorted { $0.index < $1.index }
        plannedSetCursor = 0
        if let first = plannedSpecs.first {
            currentExerciseId = item.exerciseId
            currentWeightKg = first.weightKg
            currentVLCeiling = item.vlCeiling
            if let lo = item.targetVelocityMin, let hi = item.targetVelocityMax {
                currentTargetRange = lo...hi
            }
            lastResolvedRest = first.restSeconds
        }
        currentTemplateItemId = item.id
        persistResumeCursor()
    }

    /// V2: prepare-but-don't-start hook. Same parameter shape as `start(...)`,
    /// gives the SetReady screen a way to confirm sensors / HK auth before the
    /// user taps "本组开始". Commit 3 is where this gets fully wired into the
    /// V2 SetReady flow; commit 2 only ships the surface.
    public func prepareSet(
        exerciseId: String,
        weightKg: Double,
        velocityVariant: VelocityVariant = .mv,
        targetRange: ClosedRange<Double>? = nil,
        vlCeiling: Double? = nil,
        side: Side = .both,
        defaultRestSeconds: Int = 90
    ) async {
        if isRunning { return }
        currentExerciseId = exerciseId
        currentWeightKg = weightKg
        currentVelocityVariant = velocityVariant
        currentTargetRange = targetRange
        currentVLCeiling = vlCeiling
        currentSide = side
        if lastResolvedRest == 0 { lastResolvedRest = defaultRestSeconds }
    }

    @discardableResult
    public func complete() async -> WorkoutSnapshot {
        return await completeWithFeedback(rpe: nil, notes: nil)
    }

    /// Complete the session and stamp the snapshot with subjective feedback
    /// before returning. Watch's Summary screen passes the user's RPE +
    /// post-workout note here so the snapshot reaching iPhone is complete.
    @discardableResult
    public func completeWithFeedback(rpe: Int?, notes: String?) async -> WorkoutSnapshot {
        var snapshot = await session.complete()
        if let rpe { snapshot.rpe = rpe }
        if let notes, !notes.isEmpty { snapshot.notes = notes }
        finishedSnapshot = snapshot
        isCompleted = true
        isRunning = false
        consumerTask?.cancel()
        consumerTask = nil
        clearPlanned()
        clearResumeCursor()
        // Fire before any inbound work (WCSession.send by caller) so the wrist
        // gets the cue even if the app is backgrounded immediately after.
        HapticFeedback.workoutEnded()
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
            HapticFeedback.rep(status)

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
        // Note: plannedSpecs / plannedSetCursor / lastResolvedRest are intentionally
        // NOT reset here — preparePlanned(item:) sets them BEFORE start() is invoked
        // so the controller can step through the plan. complete() clears them.
        // The actor's events stream is finished after complete(); rebuild.
        session = ActiveWorkoutSession()
    }

    private func clearPlanned() {
        plannedSpecs = []
        plannedSetCursor = 0
        currentTemplateItemId = nil
    }

    // MARK: - V2 resume persistence
    //
    // The plannedSpecs + cursor + templateItemId tuple is the minimum state
    // needed to resume mid-template after the watch app is killed by the
    // system. Stored in UserDefaults as JSON. The actor's in-memory rep
    // events are intentionally NOT persisted — those are recomputed when the
    // user restarts the set.

    private struct ResumeCursor: Codable {
        let templateItemId: UUID?
        let plannedSpecs: [TemplateSetSpecSnapshot]
        let plannedSetCursor: Int
    }

    private static let resumeKey = "vbt.live.resume.v1"

    public func persistResumeCursor() {
        guard !plannedSpecs.isEmpty else { return }
        let cursor = ResumeCursor(
            templateItemId: currentTemplateItemId,
            plannedSpecs: plannedSpecs,
            plannedSetCursor: plannedSetCursor
        )
        if let data = try? JSONEncoder().encode(cursor) {
            UserDefaults.standard.set(data, forKey: Self.resumeKey)
        }
    }

    public func restoreFromCursorIfPossible() {
        guard let data = UserDefaults.standard.data(forKey: Self.resumeKey),
              let cursor = try? JSONDecoder().decode(ResumeCursor.self, from: data)
        else { return }
        plannedSpecs = cursor.plannedSpecs
        plannedSetCursor = cursor.plannedSetCursor
        currentTemplateItemId = cursor.templateItemId
        if plannedSetCursor < plannedSpecs.count {
            currentWeightKg = plannedSpecs[plannedSetCursor].weightKg
            lastResolvedRest = plannedSpecs[plannedSetCursor].restSeconds
        }
    }

    public func clearResumeCursor() {
        UserDefaults.standard.removeObject(forKey: Self.resumeKey)
    }

    deinit {
        consumerTask?.cancel()
    }
}
