// WorkoutStore.swift
// VBTrainer · 2026-05
//
// WorkoutSnapshot ↔ SwiftData Workout conversion + persistence.
// Used on both Watch and iPhone (each has its own ModelContainer).

import Foundation
import SwiftData

@available(iOS 17.0, watchOS 10.0, *)
public enum WorkoutStore {
    public enum StoreError: Error {
        case duplicate(UUID)
        case persistenceFailure(Error)
    }

    @discardableResult
    public static func save(
        _ snapshot: WorkoutSnapshot,
        in context: ModelContext
    ) throws -> Workout {
        // De-dup by id
        let id = snapshot.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.id == id }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let w = Workout(
            id: snapshot.id,
            startedAt: snapshot.startedAt,
            endedAt: snapshot.endedAt,
            exerciseId: snapshot.exerciseId,
            notes: snapshot.notes,
            rpe: snapshot.rpe,
            linkedTemplateId: snapshot.linkedTemplateId,
            readinessSnapshotId: nil
        )

        // Heart-rate samples → JSON blob
        if !snapshot.heartRateSamples.isEmpty {
            w.heartRateSamplesData = try? JSONEncoder().encode(snapshot.heartRateSamples)
        }

        // Sets and reps
        var sets: [WorkoutSet] = []
        for setSnap in snapshot.sets {
            let s = WorkoutSet(
                id: setSnap.id,
                index: setSnap.index,
                weightKg: setSnap.weightKg,
                targetReps: nil,
                restAfterSeconds: setSnap.restAfterSeconds,
                side: setSnap.side,
                velocityVariant: setSnap.velocityVariant,
                targetVelocityRange: setSnap.targetRange,
                vlCeiling: setSnap.vlCeiling
            )
            for repSnap in setSnap.reps {
                let r = Rep(
                    id: repSnap.id,
                    index: repSnap.index,
                    meanVelocity: repSnap.meanVelocity,
                    peakVelocity: repSnap.peakVelocity,
                    meanPropulsiveVelocity: repSnap.meanPropulsiveVelocity,
                    timestamp: repSnap.timestamp,
                    metStatus: repSnap.metStatus
                )
                s.reps.append(r)
            }
            sets.append(s)
        }
        w.sets = sets

        context.insert(w)
        do {
            try context.save()
        } catch {
            throw StoreError.persistenceFailure(error)
        }
        return w
    }

    public static func snapshot(of workout: Workout) -> WorkoutSnapshot {
        let setSnaps: [SetSnapshot] = workout.sets
            .sorted(by: { $0.index < $1.index })
            .map { s in
                let repSnaps: [RepSnapshot] = s.reps
                    .sorted(by: { $0.index < $1.index })
                    .map { r in
                        RepSnapshot(
                            id: r.id,
                            index: r.index,
                            meanVelocity: r.meanVelocity,
                            peakVelocity: r.peakVelocity,
                            meanPropulsiveVelocity: r.meanPropulsiveVelocity ?? r.meanVelocity,
                            timestamp: r.timestamp,
                            metStatus: r.metStatus
                        )
                    }
                return SetSnapshot(
                    id: s.id,
                    index: s.index,
                    weightKg: s.weightKg,
                    velocityVariant: s.velocityVariant,
                    targetRange: s.targetVelocityRange,
                    vlCeiling: s.vlCeiling,
                    side: s.side,
                    restAfterSeconds: s.restAfterSeconds,
                    reps: repSnaps
                )
            }

        let hr: [HeartRateSample] = if let data = workout.heartRateSamplesData,
                                       let decoded = try? JSONDecoder().decode([HeartRateSample].self, from: data)
        {
            decoded
        } else {
            []
        }

        return WorkoutSnapshot(
            id: workout.id,
            exerciseId: workout.exerciseId,
            startedAt: workout.startedAt,
            endedAt: workout.endedAt ?? workout.startedAt,
            sets: setSnaps,
            heartRateSamples: hr,
            rpe: workout.rpe,
            linkedTemplateId: workout.linkedTemplateId,
            notes: workout.notes
        )
    }

    public static func recent(
        days: Int,
        in context: ModelContext
    ) -> [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.startedAt >= cutoff },
            sortBy: [SortDescriptor(\Workout.startedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    public static func all(in context: ModelContext) -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\Workout.startedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    public static func forExercise(
        _ exerciseId: String,
        in context: ModelContext
    ) -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\Workout.startedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
