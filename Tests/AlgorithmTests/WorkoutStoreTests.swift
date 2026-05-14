// WorkoutStoreTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0 — PR-T1. Pre-refactor safety net for
// `Shared/Services/WorkoutStore.swift`. Architecture audit flagged
// WorkoutStore as the highest-risk service to refactor without
// coverage: it owns the WorkoutSnapshot ↔ SwiftData boundary used by
// both Watch (saves locally then ships) and iPhone (saves on receive).
// A silent regression here would corrupt the user's training history
// for an entire session before being noticed.
//
// Coverage matrix:
//   save():
//     - Inserts when id unseen
//     - Idempotent dedup by id (returns existing, no duplicate row)
//     - Persists nested sets + reps in declared order
//     - Persists heart-rate samples as JSON blob (roundtrip)
//   snapshot():
//     - Workout ↔ WorkoutSnapshot roundtrip preserves all fields
//     - Sets/reps come back sorted by index regardless of insert order
//     - Empty heart-rate blob decodes to []
//   recent() / all() / forExercise():
//     - recent(days:) cutoff excludes older rows
//     - all() returns reverse-chronological
//     - forExercise() filters by exerciseId

import SwiftData
import XCTest

final class WorkoutStoreTests: XCTestCase {
    // MARK: - save()

    func testSaveInsertsNewWorkout() throws {
        let ctx = try makeMemoryContext()
        let snap = makeSnapshot(exerciseId: "back-squat")
        let saved = try WorkoutStore.save(snap, in: ctx)
        XCTAssertEqual(saved.id, snap.id)
        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(probe.count, 1)
        XCTAssertEqual(probe.first?.exerciseId, "back-squat")
    }

    func testSaveIsIdempotentById() throws {
        let ctx = try makeMemoryContext()
        let snap = makeSnapshot(exerciseId: "bench-press")
        let first = try WorkoutStore.save(snap, in: ctx)
        let second = try WorkoutStore.save(snap, in: ctx)
        XCTAssertEqual(first.id, second.id)
        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(probe.count, 1, "Re-saving same id must not duplicate")
    }

    func testSavePersistsNestedSetsAndReps() throws {
        let ctx = try makeMemoryContext()
        let snap = makeSnapshotWithSets(setCount: 3, repsPerSet: 5)
        try WorkoutStore.save(snap, in: ctx)

        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        let workout = try XCTUnwrap(probe.first)
        XCTAssertEqual(workout.sets.count, 3)
        let sortedSets = workout.sets.sorted(by: { $0.index < $1.index })
        XCTAssertEqual(sortedSets.map(\.index), [1, 2, 3])
        for set in sortedSets {
            XCTAssertEqual(set.reps.count, 5)
        }
    }

    func testSavePersistsHeartRateSamples() throws {
        let ctx = try makeMemoryContext()
        let hr = [
            HeartRateSample(timestamp: Date(timeIntervalSince1970: 1_700_000_000), bpm: 110),
            HeartRateSample(timestamp: Date(timeIntervalSince1970: 1_700_000_005), bpm: 125),
        ]
        var snap = makeSnapshot(exerciseId: "back-squat")
        snap.heartRateSamples = hr
        try WorkoutStore.save(snap, in: ctx)

        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        let workout = try XCTUnwrap(probe.first)
        let data = try XCTUnwrap(workout.heartRateSamplesData)
        let decoded = try JSONDecoder().decode([HeartRateSample].self, from: data)
        XCTAssertEqual(decoded, hr)
    }

    // MARK: - snapshot()

    func testSnapshotRoundtripPreservesScalarFields() throws {
        let ctx = try makeMemoryContext()
        let original = makeSnapshotWithSets(setCount: 2, repsPerSet: 3)
        try WorkoutStore.save(original, in: ctx)

        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        let workout = try XCTUnwrap(probe.first)
        let roundtrip = WorkoutStore.snapshot(of: workout)

        XCTAssertEqual(roundtrip.id, original.id)
        XCTAssertEqual(roundtrip.exerciseId, original.exerciseId)
        XCTAssertEqual(roundtrip.startedAt, original.startedAt)
        XCTAssertEqual(roundtrip.endedAt, original.endedAt)
        XCTAssertEqual(roundtrip.rpe, original.rpe)
        XCTAssertEqual(roundtrip.notes, original.notes)
        XCTAssertEqual(roundtrip.sets.count, original.sets.count)
    }

    func testSnapshotSortsByIndex() throws {
        let ctx = try makeMemoryContext()
        // Insert sets in REVERSE index order; snapshot must restore ascending.
        let reverseSets: [SetSnapshot] = (1...3).reversed().map { idx in
            SetSnapshot(
                index: idx,
                weightKg: 100,
                velocityVariant: .mv,
                targetRange: 0.45...0.65,
                vlCeiling: 0.20,
                side: .both,
                restAfterSeconds: 120,
                reps: makeReps(count: 2)
            )
        }
        let snap = WorkoutSnapshot(
            exerciseId: "back-squat",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_003_600),
            sets: reverseSets
        )
        try WorkoutStore.save(snap, in: ctx)

        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        let workout = try XCTUnwrap(probe.first)
        let roundtrip = WorkoutStore.snapshot(of: workout)
        XCTAssertEqual(roundtrip.sets.map(\.index), [1, 2, 3])
        for set in roundtrip.sets {
            XCTAssertEqual(set.reps.map(\.index), [1, 2])
        }
    }

    func testSnapshotEmptyHeartRateDecodesToEmpty() throws {
        let ctx = try makeMemoryContext()
        let snap = makeSnapshot(exerciseId: "back-squat") // no HR samples
        try WorkoutStore.save(snap, in: ctx)
        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        let workout = try XCTUnwrap(probe.first)
        let roundtrip = WorkoutStore.snapshot(of: workout)
        XCTAssertEqual(roundtrip.heartRateSamples, [])
    }

    // MARK: - recent() / all() / forExercise()

    func testRecentExcludesOlderThanCutoff() throws {
        let ctx = try makeMemoryContext()
        let now = Date()
        let cal = Calendar.current
        let oldDate = try XCTUnwrap(cal.date(byAdding: .day, value: -40, to: now))
        let recentDate = try XCTUnwrap(cal.date(byAdding: .day, value: -5, to: now))

        try WorkoutStore.save(makeSnapshot(exerciseId: "old", startedAt: oldDate), in: ctx)
        try WorkoutStore.save(makeSnapshot(exerciseId: "recent", startedAt: recentDate), in: ctx)

        let recent = WorkoutStore.recent(days: 30, in: ctx)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.exerciseId, "recent")
    }

    func testAllReturnsReverseChronological() throws {
        let ctx = try makeMemoryContext()
        let dates = [
            Date(timeIntervalSince1970: 1_700_000_000), // oldest
            Date(timeIntervalSince1970: 1_700_500_000),
            Date(timeIntervalSince1970: 1_701_000_000), // newest
        ]
        for (i, d) in dates.enumerated() {
            try WorkoutStore.save(makeSnapshot(exerciseId: "w\(i)", startedAt: d), in: ctx)
        }
        let all = WorkoutStore.all(in: ctx)
        XCTAssertEqual(all.map(\.exerciseId), ["w2", "w1", "w0"])
    }

    func testForExerciseFiltersById() throws {
        let ctx = try makeMemoryContext()
        try WorkoutStore.save(makeSnapshot(exerciseId: "back-squat"), in: ctx)
        try WorkoutStore.save(makeSnapshot(exerciseId: "bench-press"), in: ctx)
        try WorkoutStore.save(makeSnapshot(exerciseId: "back-squat"), in: ctx)

        let squats = WorkoutStore.forExercise("back-squat", in: ctx)
        XCTAssertEqual(squats.count, 2)
        XCTAssertTrue(squats.allSatisfy { $0.exerciseId == "back-squat" })
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func makeSnapshot(
        exerciseId: String,
        startedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> WorkoutSnapshot {
        WorkoutSnapshot(
            exerciseId: exerciseId,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(1800),
            sets: [],
            heartRateSamples: [],
            rpe: 7,
            notes: "test"
        )
    }

    private func makeSnapshotWithSets(setCount: Int, repsPerSet: Int) -> WorkoutSnapshot {
        var sets: [SetSnapshot] = []
        for i in 1...setCount {
            sets.append(SetSnapshot(
                index: i,
                weightKg: 100,
                velocityVariant: .mv,
                targetRange: 0.45...0.65,
                vlCeiling: 0.20,
                side: .both,
                restAfterSeconds: 120,
                reps: makeReps(count: repsPerSet)
            ))
        }
        return WorkoutSnapshot(
            exerciseId: "back-squat",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_003_600),
            sets: sets,
            heartRateSamples: [],
            rpe: 7,
            notes: nil
        )
    }

    private func makeReps(count: Int) -> [RepSnapshot] {
        var out: [RepSnapshot] = []
        for i in 1...count {
            let di = Double(i)
            out.append(RepSnapshot(
                index: i,
                meanVelocity: 0.55 - di * 0.01,
                peakVelocity: 0.65 - di * 0.01,
                meanPropulsiveVelocity: 0.58 - di * 0.01,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000 + di),
                metStatus: .met
            ))
        }
        return out
    }
}
