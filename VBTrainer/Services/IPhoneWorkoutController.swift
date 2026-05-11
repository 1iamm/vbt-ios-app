// IPhoneWorkoutController.swift
// VBTrainer · iOS · 2026-05
//
// Drives iPhone-only training (no Watch). Mirrors the LiveWorkoutController
// state shape from Watch so the same LiveWorkoutStore + PiP overlay work
// without changes:
//   .ready → .setActive → .setEnded → .restCountdown → .ready (next set) → … → .workoutEnded
//
// Per 3-round PM consensus + trainer's hardest requirement: prefill last
// set's weight × reps and let the「同上完成」main button log a set in one
// tap. Stepper chips only used when user actually wants to change values.

import Foundation
import SwiftData
import SwiftUI

@available(iOS 17.0, *)
@MainActor
public final class IPhoneWorkoutController: ObservableObject {

    // MARK: - Phase mirror (matches LiveProgressPayload.Phase semantics)

    public enum Phase: String { case ready, setActive, setEnded, resting, finished }

    @Published public private(set) var phase: Phase = .ready
    @Published public var currentWeightKg: Double = 0
    @Published public var currentReps: Int = 0
    /// Total restRemainingSec — drives PiP + screen countdown.
    @Published public private(set) var restRemainingSec: Int = 0
    @Published public private(set) var restTotalSec: Int = 0

    /// Sets logged this session (per-exercise + per-set).
    @Published public private(set) var loggedSets: [LoggedSet] = []
    @Published public private(set) var currentSetIndex: Int = 0
    @Published public private(set) var plannedSpecs: [TemplateSetSpecSnapshot] = []
    @Published public private(set) var exerciseId: String = ""
    @Published public private(set) var exerciseDisplayName: String = ""

    public struct LoggedSet: Identifiable, Equatable {
        public let id: UUID
        public let setIndex: Int
        public let weightKg: Double
        public let reps: Int
        public let rpe: Int?
        public let completedAt: Date
    }

    // MARK: - Internal

    private var liveWorkoutId: UUID = UUID()
    private var startedAt: Date = Date()
    private var restTask: Task<Void, Never>?
    private var templateId: UUID?

    public init() {}

    // MARK: - Setup

    /// Load a single-item template into the controller. For V1 we support
    /// one exercise at a time; multi-exercise wiring follows in V1.x.
    public func preparePlanned(item: TemplateItemSnapshot, templateId: UUID? = nil) {
        plannedSpecs = item.setSpecs.sorted { $0.index < $1.index }
        exerciseId = item.exerciseId
        exerciseDisplayName = ExerciseLookup.exercise(byId: item.exerciseId)?.nameZH ?? item.exerciseId
        self.templateId = templateId
        if let first = plannedSpecs.first {
            currentWeightKg = first.weightKg
            currentReps = first.reps
            restTotalSec = first.restSeconds
            restRemainingSec = first.restSeconds
        }
        currentSetIndex = 0
        loggedSets = []
        startedAt = Date()
        phase = .ready
        pushLive(.ready)
    }

    /// Ad-hoc empty workout — no plan, user fills as they go.
    public func prepareAdHoc(exerciseId: String, weightKg: Double = 60, reps: Int = 5) {
        self.plannedSpecs = []
        self.exerciseId = exerciseId
        self.exerciseDisplayName = ExerciseLookup.exercise(byId: exerciseId)?.nameZH ?? exerciseId
        self.templateId = nil
        currentWeightKg = weightKg
        currentReps = reps
        restTotalSec = 90
        restRemainingSec = 90
        currentSetIndex = 0
        loggedSets = []
        startedAt = Date()
        phase = .ready
        pushLive(.ready)
    }

    // MARK: - User actions

    /// 「完成本组」/「同上完成」main button. Logs current weight × reps
    /// as a completed set and transitions to rest.
    public func completeCurrentSet(rpe: Int? = nil) {
        guard phase == .ready || phase == .setActive else { return }
        let logged = LoggedSet(
            id: UUID(),
            setIndex: currentSetIndex,
            weightKg: currentWeightKg,
            reps: currentReps,
            rpe: rpe,
            completedAt: Date()
        )
        loggedSets.append(logged)
        phase = .setEnded
        pushLive(.setEnded)

        // After 0.4s of seeing the「完成」feedback, slide into rest.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self?.beginRest()
        }
    }

    private func beginRest() {
        phase = .resting
        restRemainingSec = restTotalSec
        startRestCountdown()
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
                // Subtle final-cue haptic — UIKit-side warning.
                #if canImport(UIKit) && os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                self.advanceToNextSet()
            }
        }
    }

    private func advanceToNextSet() {
        currentSetIndex += 1
        if currentSetIndex < plannedSpecs.count {
            // Next planned set — load its defaults but let user adjust before completing.
            let next = plannedSpecs[currentSetIndex]
            currentWeightKg = next.weightKg
            currentReps = next.reps
            restTotalSec = next.restSeconds
            restRemainingSec = next.restSeconds
            phase = .ready
            pushLive(.ready)
        } else if plannedSpecs.isEmpty {
            // Ad-hoc mode: keep going indefinitely with last values prefilled.
            phase = .ready
            pushLive(.ready)
        } else {
            // All planned sets done → workout finished.
            finishWorkout()
        }
    }

    /// Manual finish (from a「结束训练」button) or end of last set.
    public func finishWorkout(context: ModelContext? = nil, rpe: Int? = nil, notes: String? = nil) {
        restTask?.cancel()
        restTask = nil
        phase = .finished
        let endedAt = Date()
        if let context {
            saveToSwiftData(context: context, endedAt: endedAt, rpe: rpe, notes: notes)
        }
        pushLive(.workoutEnded)
    }

    // MARK: - Persistence

    private func saveToSwiftData(context: ModelContext, endedAt: Date, rpe: Int?, notes: String?) {
        let workout = Workout(
            id: UUID(),
            startedAt: startedAt,
            endedAt: endedAt,
            exerciseId: exerciseId,
            notes: notes,
            rpe: rpe,
            linkedTemplateId: templateId,
            readinessSnapshotId: nil,
            source: .iPhone
        )
        context.insert(workout)
        for (idx, ls) in loggedSets.enumerated() {
            let set = WorkoutSet(
                index: idx,
                weightKg: ls.weightKg,
                restAfterSeconds: restTotalSec
            )
            set.workout = workout
            context.insert(set)
            // Synthesize one Rep row per logged rep so totalReps / totalVolumeKg
            // aggregate work the same way as Watch-recorded workouts. velocity
            // values are 0 (manual mode); algorithms that need velocity should
            // filter by `Workout.source == .iPhone` and skip.
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

    // MARK: - Live progress push (drives PiP + LiveWorkoutView phase)

    private func pushLive(_ p: LiveProgressPayload.Phase) {
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
            repVelocities: loggedSets.last.map { Array(repeating: 0.0, count: $0.reps) } ?? [],
            restRemainingSec: p == .restCountdown ? restRemainingSec : nil,
            restTotalSec: p == .restCountdown ? restTotalSec : nil,
            heartRate: nil
        )
        LiveWorkoutStore.shared.apply(payload)
    }
}
