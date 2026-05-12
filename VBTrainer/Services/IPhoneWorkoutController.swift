// IPhoneWorkoutController.swift
// VBTrainer · iOS · 2026-05
//
// Drives iPhone-only training (no Watch). V1.x: multi-exercise support
// — the controller now holds the entire plan, tracks a cursor across
// exercises, and saves one Workout row per exercise on finish (mirrors
// the Watch flow). Single-exercise legacy path is still supported.
//
// Phases mirror LiveProgressPayload semantics:
//   .ready → .setActive → .setEnded → .restCountdown → .ready (next set)
//     → ... → switch exercise → .ready → ... → .workoutEnded

import Foundation
import SwiftData
import SwiftUI

@available(iOS 17.0, *)
@MainActor
public final class IPhoneWorkoutController: ObservableObject {

    public enum Phase: String { case ready, setActive, setEnded, resting, finished }

    @Published public private(set) var phase: Phase = .ready
    @Published public var currentWeightKg: Double = 0
    @Published public var currentReps: Int = 0
    @Published public private(set) var restRemainingSec: Int = 0
    @Published public private(set) var restTotalSec: Int = 0

    /// Per-exercise logged sets, keyed by exercise index in plannedItems.
    @Published public private(set) var loggedSetsByExercise: [Int: [LoggedSet]] = [:]
    @Published public private(set) var currentSetIndex: Int = 0
    @Published public private(set) var plannedItems: [TemplateItemSnapshot] = []
    @Published public private(set) var currentItemIndex: Int = 0
    @Published public var sessionNotes: String = ""

    public var currentItem: TemplateItemSnapshot? {
        plannedItems.indices.contains(currentItemIndex) ? plannedItems[currentItemIndex] : nil
    }
    public var currentPlannedSpecs: [TemplateSetSpecSnapshot] {
        (currentItem?.setSpecs ?? []).sorted { $0.index < $1.index }
    }
    public var loggedSetsForCurrent: [LoggedSet] {
        loggedSetsByExercise[currentItemIndex] ?? []
    }
    public var exerciseId: String { currentItem?.exerciseId ?? "" }
    public var exerciseDisplayName: String {
        guard let id = currentItem?.exerciseId else { return "" }
        return ExerciseLookup.exercise(byId: id)?.nameZH ?? id
    }
    /// Total sets across the whole session (work only — preserves what
    /// the bottom progress bar should show).
    public var totalPlannedSets: Int {
        plannedItems.reduce(0) { $0 + max(1, $1.effectiveWorkSetCount) }
    }
    public var totalLoggedSets: Int {
        loggedSetsByExercise.values.reduce(0) { $0 + $1.count }
    }
    public var workoutStartedAt: Date { startedAt }

    public struct LoggedSet: Identifiable, Equatable {
        public let id: UUID
        public let setIndex: Int
        public let weightKg: Double
        public let reps: Int
        public let rpe: Int?
        public let completedAt: Date
    }

    private var liveWorkoutId: UUID = UUID()
    private var startedAt: Date = Date()
    private var restTask: Task<Void, Never>?
    private var templateId: UUID?

    public init() {}

    // MARK: - Setup

    /// Multi-exercise entry. `startingItemIndex` lets the caller jump straight
    /// to a specific exercise (default 0). Replaces all session state.
    public func preparePlan(items: [TemplateItemSnapshot], startingItemIndex: Int = 0, templateId: UUID? = nil) {
        let sorted = items.sorted { $0.index < $1.index }
        plannedItems = sorted
        currentItemIndex = max(0, min(startingItemIndex, max(sorted.count - 1, 0)))
        self.templateId = templateId
        loggedSetsByExercise = [:]
        startedAt = Date()
        liveWorkoutId = UUID()
        loadCurrentItem()
    }

    /// Single-exercise convenience (back-compat for ad-hoc / TodayView quick path).
    public func preparePlanned(item: TemplateItemSnapshot, templateId: UUID? = nil) {
        preparePlan(items: [item], templateId: templateId)
    }

    /// Ad-hoc empty workout — synthesizes a single TemplateItemSnapshot so
    /// the rest of the view code can stay uniform.
    public func prepareAdHoc(exerciseId: String, weightKg: Double = 60, reps: Int = 5) {
        let synthesizedItem = TemplateItemSnapshot(
            id: UUID(),
            index: 0,
            exerciseId: exerciseId,
            targetSets: 3,
            targetReps: reps,
            targetWeightKg: weightKg,
            targetVelocityMin: nil,
            targetVelocityMax: nil,
            vlCeiling: nil,
            restSeconds: 90,
            sideRaw: "both",
            setSpecs: []
        )
        preparePlan(items: [synthesizedItem])
    }

    private func loadCurrentItem() {
        currentSetIndex = 0
        let specs = currentPlannedSpecs
        if let first = specs.first {
            currentWeightKg = first.weightKg
            currentReps = first.reps
            restTotalSec = first.restSeconds
            restRemainingSec = first.restSeconds
        } else if let item = currentItem {
            currentWeightKg = item.targetWeightKg ?? 60
            currentReps = item.targetReps
            restTotalSec = item.restSeconds
            restRemainingSec = item.restSeconds
        }
        phase = .ready
        pushLive(.ready)
    }

    // MARK: - User actions

    public func completeCurrentSet(rpe: Int? = nil) {
        // V1.x: 「加一组」 during rest means「再做一组」— cancel the
        // running countdown, log the new set, then restart rest. Without
        // this the rest-phase guard silently dropped the tap and the
        // 「加一组」 button looked broken to the user.
        if phase == .resting {
            restTask?.cancel()
            restTask = nil
        }
        guard phase == .ready || phase == .setActive || phase == .resting else { return }
        let logged = LoggedSet(
            id: UUID(),
            setIndex: currentSetIndex,
            weightKg: currentWeightKg,
            reps: currentReps,
            rpe: rpe,
            completedAt: Date()
        )
        var list = loggedSetsByExercise[currentItemIndex] ?? []
        list.append(logged)
        loggedSetsByExercise[currentItemIndex] = list
        phase = .setEnded
        pushLive(.setEnded)

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self?.beginRest()
        }
    }

    /// User jumped to a different exercise via the carousel/picker. Rest
    /// is interrupted; sets logged on the previous exercise remain.
    public func switchToExercise(at index: Int) {
        guard plannedItems.indices.contains(index), index != currentItemIndex else { return }
        restTask?.cancel()
        restTask = nil
        currentItemIndex = index
        loadCurrentItem()
    }

    public func skipRest() {
        restTask?.cancel()
        restTask = nil
        advanceToNextSet()
    }

    public func adjustRestRemaining(by delta: Int) {
        let newRemaining = max(5, min(600, restRemainingSec + delta))
        let newTotal = max(5, min(600, restTotalSec + delta))
        restRemainingSec = newRemaining
        restTotalSec = newTotal
        pushLive(.restCountdown)
    }

    private func beginRest() {
        phase = .resting
        restRemainingSec = restTotalSec
        startRestCountdown()
    }

    private func startRestCountdown() {
        restTask?.cancel()
        restTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while self.restRemainingSec > 0, !Task.isCancelled {
                self.pushLive(.restCountdown)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { self.restRemainingSec -= 1 }
            }
            if !Task.isCancelled {
                self.pushLive(.restCountdown)
                #if canImport(UIKit) && os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                self.advanceToNextSet()
            }
        }
    }

    private func advanceToNextSet() {
        currentSetIndex += 1
        let specs = currentPlannedSpecs
        // 当前动作总组数：优先 setSpecs 个数；若 legacy 模板没有 specs，
        // 回退到 effectiveWorkSetCount（= targetSets）。这样避免 specs
        // 为空时第 1 组刚完就被判定「全部完成」直接跳到下一动作。
        let totalForExercise = max(specs.count, currentItem?.effectiveWorkSetCount ?? 0)
        let doneCount = loggedSetsForCurrent.count

        // 还有未完成的组 → 留在当前动作。
        if doneCount < totalForExercise {
            if currentSetIndex < specs.count {
                let next = specs[currentSetIndex]
                currentWeightKg = next.weightKg
                currentReps = next.reps
                restTotalSec = next.restSeconds
                restRemainingSec = next.restSeconds
            }
            // 若 specs 不足（legacy / ad-hoc），保持上一组的 weight/reps。
            phase = .ready
            pushLive(.ready)
            return
        }

        // 当前动作所有组已完成 → 自动切到下一动作。
        if currentItemIndex + 1 < plannedItems.count {
            currentItemIndex += 1
            loadCurrentItem()
            return
        }

        // 纯 ad-hoc 单动作：无限继续。
        if plannedItems.count == 1 && totalForExercise == 0 {
            phase = .ready
            pushLive(.ready)
            return
        }

        // 全部动作完成 → 整场训练结束。
        phase = .finished
        pushLive(.workoutEnded)
    }

    public func finishWorkout(context: ModelContext? = nil, rpe: Int? = nil, notes: String? = nil) {
        restTask?.cancel()
        restTask = nil
        phase = .finished
        let endedAt = Date()
        let finalNotes = notes ?? (sessionNotes.isEmpty ? nil : sessionNotes)
        if let context {
            saveToSwiftData(context: context, endedAt: endedAt, rpe: rpe, notes: finalNotes)
        }
        pushLive(.workoutEnded)
    }

    // MARK: - Last-workout lookup

    /// Fetch the most recent completed Workout for a given exerciseId so the
    /// training table can show a "上次" comparison column. Returns nil if
    /// the user has never done this exercise.
    public static func lastWorkoutSummary(exerciseId: String, in context: ModelContext, excluding workoutId: UUID? = nil) -> LastWorkoutSummary? {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 5
        guard let results = try? context.fetch(descriptor) else { return nil }
        let candidate = results.first { $0.id != workoutId }
        guard let w = candidate else { return nil }
        let sets = w.sets.sorted { $0.index < $1.index }
        let topSet = sets.max { $0.weightKg < $1.weightKg }
        return LastWorkoutSummary(
            startedAt: w.startedAt,
            setCount: sets.count,
            topWeightKg: topSet?.weightKg ?? 0,
            topReps: topSet?.reps.count ?? 0
        )
    }

    public struct LastWorkoutSummary: Equatable {
        public let startedAt: Date
        public let setCount: Int
        public let topWeightKg: Double
        public let topReps: Int
    }

    // MARK: - Persistence

    private func saveToSwiftData(context: ModelContext, endedAt: Date, rpe: Int?, notes: String?) {
        // One Workout per exercise that actually got any logged sets.
        for (idx, item) in plannedItems.enumerated() {
            let sets = loggedSetsByExercise[idx] ?? []
            guard !sets.isEmpty else { continue }
            let workout = Workout(
                id: UUID(),
                startedAt: startedAt,
                endedAt: endedAt,
                exerciseId: item.exerciseId,
                notes: notes,
                rpe: rpe,
                linkedTemplateId: templateId,
                readinessSnapshotId: nil,
                source: .iPhone
            )
            context.insert(workout)
            for (setIdx, ls) in sets.enumerated() {
                let set = WorkoutSet(
                    index: setIdx,
                    weightKg: ls.weightKg,
                    restAfterSeconds: restTotalSec
                )
                set.workout = workout
                context.insert(set)
                for r in 0..<ls.reps {
                    let rep = Rep(
                        index: r + 1,
                        meanVelocity: 0,
                        peakVelocity: 0,
                        meanPropulsiveVelocity: nil,
                        timestamp: ls.completedAt,
                        metStatus: .met
                    )
                    rep.set = set
                    context.insert(rep)
                }
            }
            do {
                try context.save()
                NotificationCenter.default.post(name: .vbtWorkoutImported, object: workout.id)
            } catch {
                #if DEBUG
                print("[IPhoneWorkoutController] save error: \(error)")
                #endif
            }
        }
    }

    // MARK: - Live progress push

    private func pushLive(_ p: LiveProgressPayload.Phase) {
        let last = loggedSetsForCurrent.last
        let payload = LiveProgressPayload(
            phase: p,
            workoutId: liveWorkoutId,
            setIndex: currentSetIndex,
            exerciseName: exerciseDisplayName,
            targetReps: currentReps,
            targetWeightKg: currentWeightKg,
            currentRep: currentReps,
            lastRepVelocity: nil,
            setBestVelocity: nil,
            vlPercent: nil,
            repVelocities: last.map { Array(repeating: 0.0, count: $0.reps) } ?? [],
            restRemainingSec: p == .restCountdown ? restRemainingSec : nil,
            restTotalSec: p == .restCountdown ? restTotalSec : nil,
            heartRate: nil
        )
        LiveWorkoutStore.shared.apply(payload)
    }
}
