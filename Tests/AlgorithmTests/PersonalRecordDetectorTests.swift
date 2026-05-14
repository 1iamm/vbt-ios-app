// PersonalRecordDetectorTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0 — PR-T2 (part 2). Coverage for the append-only PR
// detector. The detector is called on every Workout save; if a regression
// stops detecting PRs the user permanently loses recognition of a real
// training milestone, and if it spuriously fires duplicates the PR list
// becomes noise.
//
// Coverage matrix:
//   maxWeight             — fires on first workout (no prior)
//   maxWeight             — fires when current beats prior
//   maxWeight             — does NOT fire when current matches prior
//   maxVolume             — fires on first volume row
//   maxSingleRepVelocity  — fires on highest peakVelocity rep
//   no-op                 — empty workout (zero sets) inserts nothing
//   isolation by exerciseId — back-squat PR does not block bench-press

import SwiftData
import XCTest

final class PersonalRecordDetectorTests: XCTestCase {
    func testFirstWorkoutEverGeneratesMaxWeightAndVolumePR() throws {
        let ctx = try makeMemoryContext()
        let workout = makeWorkout(exerciseId: "back-squat", weight: 100, reps: 5, peakVel: 0.55)
        ctx.insert(workout)
        try ctx.save()

        PersonalRecordDetector.checkAndRecord(workout: workout, in: ctx)

        let prs = try ctx.fetch(FetchDescriptor<PersonalRecord>())
        let kinds = Set(prs.map(\.kind))
        XCTAssertTrue(kinds.contains(.maxWeight))
        XCTAssertTrue(kinds.contains(.maxVolume))
        XCTAssertTrue(kinds.contains(.maxSingleRepVelocity))
    }

    func testHeavierWeightCreatesNewMaxWeightPR() throws {
        let ctx = try makeMemoryContext()

        // First workout @ 100kg
        let w1 = makeWorkout(exerciseId: "back-squat", weight: 100, reps: 5, peakVel: 0.55)
        ctx.insert(w1)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: w1, in: ctx)

        // Second workout @ 110kg
        let w2 = makeWorkout(exerciseId: "back-squat", weight: 110, reps: 5, peakVel: 0.55)
        ctx.insert(w2)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: w2, in: ctx)

        let maxWeightPRs = try ctx.fetch(FetchDescriptor<PersonalRecord>())
            .filter { $0.kind == .maxWeight }
            .sorted { $0.achievedAt < $1.achievedAt }
        XCTAssertEqual(maxWeightPRs.count, 2)
        XCTAssertEqual(maxWeightPRs.map(\.value), [100, 110])
    }

    func testEqualWeightDoesNotCreateNewMaxWeightPR() throws {
        let ctx = try makeMemoryContext()
        let w1 = makeWorkout(exerciseId: "back-squat", weight: 100, reps: 5, peakVel: 0.55)
        ctx.insert(w1)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: w1, in: ctx)

        let w2 = makeWorkout(exerciseId: "back-squat", weight: 100, reps: 5, peakVel: 0.55)
        ctx.insert(w2)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: w2, in: ctx)

        let maxWeightPRs = try ctx.fetch(FetchDescriptor<PersonalRecord>())
            .filter { $0.kind == .maxWeight }
        XCTAssertEqual(maxWeightPRs.count, 1, "Equal-weight workout must not spawn a second PR")
    }

    func testFasterRepCreatesNewVelocityPR() throws {
        let ctx = try makeMemoryContext()
        let w1 = makeWorkout(exerciseId: "back-squat", weight: 100, reps: 5, peakVel: 0.55)
        ctx.insert(w1)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: w1, in: ctx)

        let w2 = makeWorkout(exerciseId: "back-squat", weight: 100, reps: 5, peakVel: 0.70)
        ctx.insert(w2)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: w2, in: ctx)

        let velPRs = try ctx.fetch(FetchDescriptor<PersonalRecord>())
            .filter { $0.kind == .maxSingleRepVelocity }
        XCTAssertEqual(velPRs.count, 2)
    }

    func testEmptyWorkoutInsertsNoPRs() throws {
        let ctx = try makeMemoryContext()
        let empty = Workout(
            startedAt: Date(),
            endedAt: Date(),
            exerciseId: "back-squat"
        )
        ctx.insert(empty)
        try ctx.save()

        PersonalRecordDetector.checkAndRecord(workout: empty, in: ctx)
        let prs = try ctx.fetch(FetchDescriptor<PersonalRecord>())
        XCTAssertEqual(prs.count, 0, "Empty workout must not produce phantom PRs")
    }

    func testIsolationBetweenExercises() throws {
        let ctx = try makeMemoryContext()
        let squat = makeWorkout(exerciseId: "back-squat", weight: 150, reps: 5, peakVel: 0.55)
        ctx.insert(squat)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: squat, in: ctx)

        let bench = makeWorkout(exerciseId: "bench-press", weight: 80, reps: 5, peakVel: 0.55)
        ctx.insert(bench)
        try ctx.save()
        PersonalRecordDetector.checkAndRecord(workout: bench, in: ctx)

        let benchMaxWeight = try ctx.fetch(FetchDescriptor<PersonalRecord>())
            .filter { $0.exerciseId == "bench-press" && $0.kind == .maxWeight }
        XCTAssertEqual(benchMaxWeight.count, 1, "First bench workout must produce its own PR despite heavier squat")
        XCTAssertEqual(benchMaxWeight.first?.value, 80)
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func makeWorkout(
        exerciseId: String,
        weight: Double,
        reps: Int,
        peakVel: Double
    ) -> Workout {
        let workout = Workout(
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(1800),
            exerciseId: exerciseId
        )
        let set = WorkoutSet(index: 1, weightKg: weight)
        for i in 1...reps {
            let rep = Rep(
                index: i,
                meanVelocity: 0.50,
                peakVelocity: peakVel,
                meanPropulsiveVelocity: 0.52,
                timestamp: Date(),
                metStatus: .met
            )
            set.reps.append(rep)
        }
        workout.sets = [set]
        return workout
    }
}
