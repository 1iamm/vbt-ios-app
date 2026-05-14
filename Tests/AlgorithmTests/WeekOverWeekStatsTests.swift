// WeekOverWeekStatsTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0.5 (Round 2 Architect P2): cover WeekOverWeekStats —
// pure function with zero unit tests, used by Stats tab headline +
// CelebrationResolver narrative.

import SwiftData
import XCTest

@MainActor
final class WeekOverWeekStatsTests: XCTestCase {
    // MARK: - WeekOverWeekHeadline.deltaPercent

    func testDeltaPercentZeroWhenLastZeroAndThisZero() {
        let h = WeekOverWeekHeadline()
        XCTAssertEqual(h.deltaPercent(0, 0), 0)
    }

    func testDeltaPercent100WhenLastZeroAndThisPositive() {
        let h = WeekOverWeekHeadline()
        XCTAssertEqual(h.deltaPercent(50, 0), 100)
    }

    func testDeltaPercentRatio() {
        let h = WeekOverWeekHeadline()
        XCTAssertEqual(h.deltaPercent(110, 100), 10, accuracy: 1e-9)
        XCTAssertEqual(h.deltaPercent(80, 100), -20, accuracy: 1e-9)
    }

    // MARK: - WeekOverWeekStats.headline

    func testHeadlineEmpty() throws {
        let ctx = try makeMemoryContext()
        let h = WeekOverWeekStats.headline(now: Date(), context: ctx)
        XCTAssertEqual(h.thisWeekCount, 0)
        XCTAssertEqual(h.lastWeekCount, 0)
        XCTAssertEqual(h.thisWeekVolume, 0)
    }

    func testHeadlineBucketsByWeek() throws {
        let ctx = try makeMemoryContext()
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        var cal = Calendar.current
        cal.firstWeekday = 2
        let thisStart = cal.dateInterval(of: .weekOfYear, for: ref)!.start
        let lastStart = cal.date(byAdding: .day, value: -7, to: thisStart)!

        let thisWorkout = makeWorkout(
            startedAt: cal.date(byAdding: .hour, value: 12, to: thisStart)!,
            sets: [(100, 5), (100, 5)]
        )
        let lastWorkout = makeWorkout(
            startedAt: cal.date(byAdding: .hour, value: 12, to: lastStart)!,
            sets: [(80, 5)]
        )
        let outsideWorkout = makeWorkout(
            startedAt: cal.date(byAdding: .day, value: -14, to: thisStart)!,
            sets: [(60, 5)]
        )
        ctx.insert(thisWorkout)
        ctx.insert(lastWorkout)
        ctx.insert(outsideWorkout)
        try ctx.save()

        let h = WeekOverWeekStats.headline(now: ref, context: ctx)
        XCTAssertEqual(h.thisWeekCount, 1)
        XCTAssertEqual(h.lastWeekCount, 1)
        XCTAssertEqual(h.thisWeekVolume, 1000, accuracy: 0.001)
        XCTAssertEqual(h.lastWeekVolume, 400, accuracy: 0.001)
    }

    func testHeadlineAvgVelocityReflectsReps() throws {
        let ctx = try makeMemoryContext()
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        var cal = Calendar.current
        cal.firstWeekday = 2
        let thisStart = cal.dateInterval(of: .weekOfYear, for: ref)!.start

        let w = makeWorkout(
            startedAt: cal.date(byAdding: .hour, value: 12, to: thisStart)!,
            sets: [(100, 5)],
            mv: 0.5
        )
        ctx.insert(w)
        try ctx.save()

        let h = WeekOverWeekStats.headline(now: ref, context: ctx)
        XCTAssertEqual(h.thisWeekAvgVelocity, 0.5, accuracy: 1e-9)
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func makeWorkout(
        startedAt: Date,
        sets: [(weight: Double, reps: Int)],
        mv: Double = 0.5
    ) -> Workout {
        let w = Workout(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(1800),
            exerciseId: "back-squat"
        )
        var swiftSets: [WorkoutSet] = []
        for (i, t) in sets.enumerated() {
            let s = WorkoutSet(index: i + 1, weightKg: t.weight)
            for j in 1...t.reps {
                s.reps.append(Rep(
                    index: j,
                    meanVelocity: mv,
                    peakVelocity: mv + 0.1,
                    meanPropulsiveVelocity: mv + 0.05,
                    timestamp: startedAt,
                    metStatus: .met
                ))
            }
            swiftSets.append(s)
        }
        w.sets = swiftSets
        return w
    }
}
