// PersonalRecordDetector.swift
// VBTrainer · 2026-05
//
// On every newly-saved Workout, check whether any PR is beaten and insert
// a new PersonalRecord row. Append-only — historical PRs are preserved.

import Foundation
import SwiftData

@available(iOS 17.0, watchOS 10.0, *)
public enum PersonalRecordDetector {

    public static func checkAndRecord(
        workout: Workout,
        in context: ModelContext
    ) {
        let exId = workout.exerciseId
        let prevDescriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { $0.exerciseId == exId }
        )
        let prev = (try? context.fetch(prevDescriptor)) ?? []

        // 1. maxWeight — heaviest single rep
        let maxWeight = workout.sets.map(\.weightKg).max() ?? 0
        let prevMaxWeight = prev.filter { $0.kind == .maxWeight }.map(\.value).max() ?? 0
        if maxWeight > prevMaxWeight && maxWeight > 0 {
            let pr = PersonalRecord(
                exerciseId: exId,
                kind: .maxWeight,
                value: maxWeight,
                achievedAt: workout.startedAt,
                sourceWorkoutId: workout.id
            )
            context.insert(pr)
        }

        // 2. maxVolume — total kg·reps
        let totalVolume = workout.totalVolumeKg
        let prevMaxVolume = prev.filter { $0.kind == .maxVolume }.map(\.value).max() ?? 0
        if totalVolume > prevMaxVolume && totalVolume > 0 {
            let pr = PersonalRecord(
                exerciseId: exId,
                kind: .maxVolume,
                value: totalVolume,
                achievedAt: workout.startedAt,
                sourceWorkoutId: workout.id
            )
            context.insert(pr)
        }

        // 3. maxSingleRepVelocity
        let maxVel = workout.sets.flatMap(\.reps).map(\.peakVelocity).max() ?? 0
        let prevMaxVel = prev.filter { $0.kind == .maxSingleRepVelocity }.map(\.value).max() ?? 0
        if maxVel > prevMaxVel && maxVel > 0 {
            let pr = PersonalRecord(
                exerciseId: exId,
                kind: .maxSingleRepVelocity,
                value: maxVel,
                achievedAt: workout.startedAt,
                sourceWorkoutId: workout.id
            )
            context.insert(pr)
        }

        // 4. e1RM (only if LVP computable)
        if let exercise = ExerciseLookup.exercise(byId: exId),
           let v1RM = exercise.referenceV1RM {
            let allWorkouts = WorkoutStore.forExercise(exId, in: context)
            let points = LVPCalculator.points(from: allWorkouts, variant: exercise.defaultVelocityVariant)
            if let fit = LVPCalculator.fit(points: points),
               let e1rm = LVPCalculator.estimate1RM(fit: fit, v1RM: v1RM) {
                let prevE1RM = prev.filter { $0.kind == .e1RM }.map(\.value).max() ?? 0
                if e1rm > prevE1RM {
                    let pr = PersonalRecord(
                        exerciseId: exId,
                        kind: .e1RM,
                        value: e1rm,
                        achievedAt: workout.startedAt,
                        sourceWorkoutId: workout.id
                    )
                    context.insert(pr)
                }
            }
        }

        try? context.save()
    }
}
