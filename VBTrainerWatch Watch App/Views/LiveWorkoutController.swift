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
    /// Mutable so SetReady can let the user adjust weight per set via Crown / +/- buttons
    /// before tapping「本组开始」. Persisted into the session at start time.
    @Published public var currentWeightKg: Double = 0
    /// Mutable target reps for the current set (display-only — algorithm doesn't
    /// auto-end at target; user taps「结束本组」). Adjustable in SetReady.
    @Published public var currentReps: Int = 0
    public private(set) var currentVelocityVariant: VelocityVariant = .mv
    /// Mutable so SetReady can adjust MV bounds via Crown.
    @Published public var currentTargetRange: ClosedRange<Double>?
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

    /// Multi-exercise plan: the full ordered list of exercises in this
    /// workout. `plannedItems[plannedItemCursor]` is the one the user is
    /// currently doing; `plannedSpecs` mirrors that item's set specs.
    @Published public private(set) var plannedItems: [TemplateItemSnapshot] = []
    @Published public private(set) var plannedItemCursor: Int = 0

    /// Buffer per-exercise snapshots so the workout-end sync can deliver
    /// one record per exercise. session.complete() is called at each
    /// exercise transition; each snapshot is appended here.
    public private(set) var pendingExerciseSnapshots: [WorkoutSnapshot] = []

    /// Whole-workout start time (set when the user taps「本组开始」on the
    /// first exercise's first set).
    public private(set) var workoutStartedAt: Date?

    // MARK: - Internal

    private var session = ActiveWorkoutSession()
    private var consumerTask: Task<Void, Never>?

    /// First-rep velocity within the current set, used to compute live VL%.
    private var setBaselineVelocity: Double?

    /// Best velocity seen in the current set — used for VL% basis (per
    /// trainer R2: bar chart + speed colors compute drop% against best rep,
    /// not first rep, since rep 1 may be slow warming up).
    private var setBestVelocity: Double = 0

    /// Velocities of every rep in the current set, accumulated for the
    /// `.setEnded` LiveProgressPayload bar chart.
    private var setRepVelocities: [Double] = []

    /// Unique id for this whole training session (multi-exercise). Used by
    /// the iPhone-side LiveWorkoutStore to detect new sessions vs same.
    private var liveWorkoutId: UUID = UUID()

    /// Rest countdown task — runs while in .setEnded → restCountdown phase,
    /// posts ticks to iPhone at 1Hz. Cancelled on next start / cancel.
    private var restCountdownTask: Task<Void, Never>?

    /// 12-second inactivity timer per trainer痛点：做完想做的最后一 rep 停
    /// 5s 不动 → 自动结组。Reset on every rep, cancelled on manual endSet.
    private var inactivityTask: Task<Void, Never>?

    /// Synchronously-set re-entrancy guard. `isRunning` only flips to true
    /// after the (awaited) session.start completes; without `isStarting`,
    /// two concurrent callers (SetReady + LiveSet.task) both observe
    /// `isRunning == false` and proceed → the second start hits MotionManager
    /// inside a second ActiveWorkoutSession instance, throwing
    /// MotionError.alreadyRunning.
    private var isStarting = false

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
        // Idempotent: if already running or in flight, no-op.
        if isRunning || isStarting { return }
        isStarting = true
        defer { isStarting = false }
        // Fresh start: rebuild session and reset all mirrors. preparePlanned()
        // may have already populated currentTargetRange / currentVLCeiling /
        // currentExerciseId before this call — keep those when a plan is loaded.
        resetForNewWorkout()
        // Capture whole-workout start once. start() is called per-exercise
        // for multi-exercise plans; only the first call sets the baseline.
        if workoutStartedAt == nil { workoutStartedAt = Date() }
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
            // V2.x live progress: push .ready so iPhone presents the
            // fullScreenCover (per PM Round-3: button triggers cover,
            // not first-rep detection — trainer wants certainty).
            setBestVelocity = 0
            setRepVelocities = []
            pushLiveProgress(phase: .ready)
            resetInactivityTimer()
        } catch {
            errorMessage = "训练开始失败：\(error.localizedDescription)"
            consumerTask?.cancel()
            consumerTask = nil
        }
    }

    public func endSet() async {
        // If session is running, properly close out via the actor. If a
        // previous start failed (e.g. HK unavailable), session is idle —
        // but we STILL advance the planned cursor so user isn't stuck
        // looping on set 1 forever.
        if isRunning {
            await session.endSet()
        }
        plannedSetCursor += 1

        if plannedSetCursor < plannedSpecs.count {
            // Still more sets in the current exercise.
            let next = plannedSpecs[plannedSetCursor]
            currentWeightKg = next.weightKg
            currentReps = next.reps
            lastResolvedRest = next.restSeconds
        } else if hasMoreExercises {
            // Last set of current exercise → snapshot it into the buffer,
            // wipe the session so the next exercise's start() comes up fresh,
            // and advance the item cursor.
            if isRunning {
                let snap = await session.complete()
                pendingExerciseSnapshots.append(snap)
            }
            isRunning = false
            consumerTask?.cancel()
            consumerTask = nil
            plannedItemCursor += 1
            loadCurrentItemIntoSpecs()
            // Fresh session for the next exercise's start().
            session = ActiveWorkoutSession()
        }
        // else: this was the last set of the last exercise. Leave session
        // running; WorkoutDone's completeWithFeedback handles the final flush.

        persistResumeCursor()
        HapticFeedback.setEnded()

        // V2.x live progress: push .setEnded with bar-chart data, then run
        // 1Hz rest countdown ticks until they reach 0. iPhone uses these
        // to drive the RestView screen.
        cancelInactivityTimer()
        let setVels = setRepVelocities
        pushLiveProgress(phase: .setEnded, repsForBar: setVels)
        startRestCountdownPush(seconds: lastResolvedRest)
        // Reset accumulators for next set.
        setRepVelocities = []
        setBestVelocity = 0
    }

    /// Called when Watch RestView's countdown finishes / user taps「跳过」 /
    /// iPhone pushes restSkip. Cancels the 1Hz countdown push task and tells
    /// iPhone the rest is over so its fullScreenCover transitions away from
    /// RestView (either to ReadyOverlay for next set or dismiss for end).
    public func endRestNowAndAdvanceLiveProgress() {
        restCountdownTask?.cancel()
        restCountdownTask = nil
        if !plannedItems.isEmpty
            && plannedItemCursor >= plannedItems.count - 1
            && plannedSetCursor >= plannedSpecs.count {
            // No more sets anywhere → workout is done.
            pushLiveProgress(phase: .workoutEnded)
        } else {
            // Either more sets in current exercise or another exercise pending.
            // Push .ready so iPhone shows ReadyOverlay waiting for first rep.
            pushLiveProgress(phase: .ready)
        }
    }

    /// 1Hz tick pushing `.restCountdown` to iPhone with restRemainingSec.
    /// Stopped on next .ready (next set starts) or manual cancel.
    /// 1Hz tick is now driven by `WatchRestView` itself (single source of
    /// truth for the View's @State counter). Controller only kicks off the
    /// first restCountdown push so iPhone immediately sees the new phase;
    /// View's onAppear / tick / ±10s callbacks call `pushRestCountdownNow`
    /// from then on.
    private func startRestCountdownPush(seconds: Int) {
        restCountdownTask?.cancel()
        restCountdownTask = nil
        let total = max(1, seconds)
        pushLiveProgress(phase: .restCountdown, restRemaining: total, restTotal: total)
    }

    /// V2 unified entry: SetReady's「本组开始」button calls this — picks
    /// start (first set) vs startNextSet (subsequent) based on session state.
    /// Always uses the (possibly user-adjusted) `currentWeightKg`.
    public func beginCurrentSet() async {
        if !isRunning {
            await start(
                exerciseId: currentExerciseId,
                weightKg: currentWeightKg,
                velocityVariant: currentVelocityVariant,
                targetRange: currentTargetRange,
                vlCeiling: currentVLCeiling,
                side: currentSide,
                defaultRestSeconds: currentRestSeconds
            )
        } else {
            await startNextSet(weightKg: currentWeightKg)
        }
    }

    /// Bump current weight by `delta` kg, clamped to [0, 500].
    public func adjustCurrentWeight(by delta: Double) {
        currentWeightKg = max(0, min(500, currentWeightKg + delta))
    }

    /// Bump current reps target by `delta`, clamped to [1, 99].
    public func adjustCurrentReps(by delta: Int) {
        currentReps = max(1, min(99, currentReps + delta))
    }

    /// Set MV target lower bound, clamped to [0.05, upper - 0.05].
    public func setTargetMVLow(_ value: Double) {
        let upper = currentTargetRange?.upperBound ?? 0.70
        let low = max(0.05, min(upper - 0.05, value))
        currentTargetRange = low...upper
    }

    /// Set MV target upper bound, clamped to [lower + 0.05, 2.0].
    public func setTargetMVHigh(_ value: Double) {
        let lower = currentTargetRange?.lowerBound ?? 0.45
        let high = max(lower + 0.05, min(2.0, value))
        currentTargetRange = lower...high
    }

    /// Inspect the next planned set's parameters (used by Rest screen to
    /// auto-fill the "下一组" button). Returns nil when no plan or finished.
    public var nextPlannedParams: (weightKg: Double, reps: Int, rest: Int, isWarmUp: Bool)? {
        guard !plannedSpecs.isEmpty, plannedSetCursor < plannedSpecs.count else { return nil }
        let s = plannedSpecs[plannedSetCursor]
        return (s.weightKg, s.reps, s.restSeconds, s.kindRaw == "warmUp")
    }

    /// Start the next set. Caller-supplied `weightKg` (e.g. from SetReady's
    /// adjusted `currentWeightKg`) wins over `plannedSpecs[cursor]`; rest
    /// duration still comes from the plan when available.
    public func startNextSet(
        weightKg: Double? = nil,
        velocityVariant: VelocityVariant? = nil,
        targetRange: ClosedRange<Double>? = nil,
        vlCeiling: Double? = nil,
        side: Side? = nil
    ) async {
        let resolvedWeight: Double
        let resolvedRest: Int?
        if let explicit = weightKg {
            resolvedWeight = explicit
            resolvedRest = nextPlannedParams?.rest
        } else if let next = nextPlannedParams {
            resolvedWeight = next.weightKg
            resolvedRest = next.rest
        } else {
            resolvedWeight = currentWeightKg
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
    /// the first spec's params. **Single-item entrypoint** — use
    /// `preparePlan(items:startingItemIndex:)` for multi-exercise flows.
    public func preparePlanned(item: TemplateItemSnapshot) {
        plannedItems = [item]
        plannedItemCursor = 0
        loadCurrentItemIntoSpecs()
    }

    /// V2 multi-exercise entry: load the whole plan into the controller and
    /// position the cursor on the user-tapped exercise. After this,
    /// `endSet()` will automatically advance through sets within the current
    /// exercise and then through subsequent exercises until the plan is
    /// exhausted.
    public func preparePlan(items: [TemplateItemSnapshot], startingItemIndex: Int = 0) {
        let sorted = items.sorted { $0.index < $1.index }
        plannedItems = sorted
        plannedItemCursor = max(0, min(startingItemIndex, max(sorted.count - 1, 0)))
        pendingExerciseSnapshots = []
        workoutStartedAt = nil
        loadCurrentItemIntoSpecs()
    }

    private func loadCurrentItemIntoSpecs() {
        guard plannedItemCursor < plannedItems.count else { return }
        let item = plannedItems[plannedItemCursor]
        plannedSpecs = item.setSpecs.sorted { $0.index < $1.index }
        plannedSetCursor = 0
        if let first = plannedSpecs.first {
            currentExerciseId = item.exerciseId
            currentWeightKg = first.weightKg
            currentReps = first.reps
            currentVLCeiling = item.vlCeiling
            if let lo = item.targetVelocityMin, let hi = item.targetVelocityMax {
                currentTargetRange = lo...hi
            }
            lastResolvedRest = first.restSeconds
        }
        currentTemplateItemId = item.id
        persistResumeCursor()
    }

    /// True when there's still another exercise after the current one.
    public var hasMoreExercises: Bool {
        plannedItemCursor + 1 < plannedItems.count
    }

    /// True when all planned exercises + their sets are done.
    public var isPlanFullyComplete: Bool {
        !plannedItems.isEmpty
            && plannedItemCursor >= plannedItems.count - 1
            && plannedSetCursor >= plannedSpecs.count
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
        cancelInactivityTimer()
        restCountdownTask?.cancel()
        restCountdownTask = nil
        clearPlanned()
        clearResumeCursor()
        // Fire before any inbound work (WCSession.send by caller) so the wrist
        // gets the cue even if the app is backgrounded immediately after.
        HapticFeedback.workoutEnded()
        // V2.x live progress: tell iPhone the workout is over so it can
        // dismiss the fullScreenCover.
        pushLiveProgress(phase: .workoutEnded)
        return snapshot
    }

    /// Multi-exercise flush: combines pendingExerciseSnapshots (collected at
    /// each exercise transition by endSet()) with the final snapshot. Caller
    /// is expected to send each via WatchConnectivityService.
    @discardableResult
    public func completeAllWithFeedback(rpe: Int?, notes: String?) async -> [WorkoutSnapshot] {
        let final = await completeWithFeedback(rpe: rpe, notes: notes)
        var all = pendingExerciseSnapshots
        all.append(final)
        pendingExerciseSnapshots = []
        return all
    }

    /// Total elapsed workout duration in seconds, since the very first start().
    public var totalWorkoutSeconds: Int {
        guard let started = workoutStartedAt else { return 0 }
        return max(0, Int(Date().timeIntervalSince(started)))
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
            setBestVelocity = max(setBestVelocity, repEvent.meanVelocity)
            setRepVelocities.append(repEvent.meanVelocity)
            HapticFeedback.rep(status)
            pushLiveProgress(phase: .repDetected)
            resetInactivityTimer()

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

        case .vlCeilingExceeded(let vl, let ceiling):
            NotificationCenter.default.post(
                name: .vbtVLCeilingExceeded,
                object: nil,
                userInfo: ["vl": vl, "threshold": ceiling]
            )

        case .stateChanged, .restTick:
            break
        }
    }

    // MARK: - Live progress push to iPhone

    private func pushLiveProgress(phase: LiveProgressPayload.Phase, repsForBar: [Double]? = nil, restRemaining: Int? = nil, restTotal: Int? = nil) {
        let exName = currentExerciseId.isEmpty ? "训练" : currentExerciseId
        let payload = LiveProgressPayload(
            phase: phase,
            workoutId: liveWorkoutId,
            setIndex: plannedSetCursor,
            exerciseName: exName,
            targetReps: currentReps,
            targetWeightKg: currentWeightKg,
            currentRep: rep,
            lastRepVelocity: phase == .repDetected ? velocity : nil,
            setBestVelocity: setBestVelocity > 0 ? setBestVelocity : nil,
            vlPercent: vlPercent,
            repVelocities: repsForBar ?? [],
            restRemainingSec: restRemaining,
            restTotalSec: restTotal,
            heartRate: heartRate > 0 ? heartRate : nil,
            targetVelocityMin: currentTargetRange?.lowerBound,
            targetVelocityMax: currentTargetRange?.upperBound
        )
        WatchConnectivityService.shared.send(message: .liveProgress(payload))
    }

    /// Called when user adjusts rest seconds on Watch via ±10s buttons.
    /// Immediately pushes a new `.restCountdown` with the updated values so
    /// iPhone doesn't have to wait for next 1Hz tick. Also updates the
    /// total since user may extend total rest time.
    public func pushRestCountdownNow(remaining: Int, total: Int) {
        pushLiveProgress(phase: .restCountdown, restRemaining: remaining, restTotal: total)
    }

    /// Inactivity timer constants. PR #55 (Round 1 fix IX-F3): bumped from
    /// 5s → 12s because heavy compound lifts (1-5RM Squat/DL) routinely
    /// rack the bar 5-7s between reps within the same set. 5s was closing
    /// the set mid-effort and pushing the next rep into the next set's
    /// data — a data-correctness bug, not just UX.
    ///
    /// 8s pre-warning gives the user a haptic cue 4s before the auto-end
    /// so they can raise their wrist and decide to keep lifting. The warning
    /// only fires if `enableRepHaptic` is on (consistent with rep haptics).
    private static let inactivityWarnNanos: UInt64 = 8_000_000_000
    private static let inactivityEndNanos: UInt64 = 12_000_000_000

    /// Reset the inactivity timer. Called after every rep. Schedules a
    /// pre-warning haptic at 8s and an auto-end at 12s. Both are cancelled
    /// if a new rep arrives or the user manually ends the set.
    private func resetInactivityTimer() {
        inactivityTask?.cancel()
        inactivityTask = Task { @MainActor [weak self] in
            // 8s pre-warning
            try? await Task.sleep(nanoseconds: Self.inactivityWarnNanos)
            guard !Task.isCancelled, let self else { return }
            if self.isRunning {
                HapticFeedback.inactivityWarning()
            }
            // 4 more seconds → 12s total → auto-end. `self` is already
            // non-Optional from the guard above (a second `let self` would
            // be a compile error against the bound non-Optional binding);
            // only re-check cancellation.
            try? await Task.sleep(nanoseconds: Self.inactivityEndNanos - Self.inactivityWarnNanos)
            guard !Task.isCancelled else { return }
            await self.inactivityAutoEnd()
        }
    }

    /// Called by the inactivity timer after 12s of no new reps. If the
    /// session is still running and a plan is loaded, auto-end this set.
    public func inactivityAutoEnd() async {
        guard isRunning else { return }
        #if DEBUG
        print("[LiveCtrl] inactivity 12s → auto endSet()")
        #endif
        await endSet()
    }

    public func cancelInactivityTimer() {
        inactivityTask?.cancel()
        inactivityTask = nil
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
