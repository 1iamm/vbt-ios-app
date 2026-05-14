// WeeklyAdherenceTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0.5 (Round 2 Architect P2): cover WeeklyAdherence — pure
// function with zero unit tests, used by TodayHeader / StatsView /
// CelebrationCoordinator. Regression silently breaks "本周满训" and
// streak displays.

import SwiftData
import XCTest

@MainActor
final class WeeklyAdherenceTests: XCTestCase {
    // MARK: - WeeklyAdherence struct

    func testCompletionRateZeroWhenNoPlanned() {
        let a = WeeklyAdherence(
            weekStart: Date(), weekEnd: Date(),
            planned: 0, completed: 0, skipped: 0, missed: 0, inProgress: 0, current: 0
        )
        XCTAssertEqual(a.completionRate, 0)
    }

    func testCompletionRateRatio() {
        let a = WeeklyAdherence(
            weekStart: Date(), weekEnd: Date(),
            planned: 4, completed: 3, skipped: 0, missed: 1, inProgress: 0, current: 0
        )
        XCTAssertEqual(a.completionRate, 0.75, accuracy: 1e-9)
    }

    func testIsFullyCompletedTrue() {
        let a = WeeklyAdherence(
            weekStart: Date(), weekEnd: Date(),
            planned: 3, completed: 3, skipped: 0, missed: 0, inProgress: 0, current: 0
        )
        XCTAssertTrue(a.isFullyCompleted)
    }

    func testIsFullyCompletedFalseWhenZeroPlanned() {
        let a = WeeklyAdherence(
            weekStart: Date(), weekEnd: Date(),
            planned: 0, completed: 0, skipped: 0, missed: 0, inProgress: 0, current: 0
        )
        XCTAssertFalse(a.isFullyCompleted, "Zero planned must not count as 满训")
    }

    func testIsFullyCompletedFalseWithOneMissed() {
        let a = WeeklyAdherence(
            weekStart: Date(), weekEnd: Date(),
            planned: 3, completed: 2, skipped: 0, missed: 1, inProgress: 0, current: 0
        )
        XCTAssertFalse(a.isFullyCompleted)
    }

    // MARK: - WeeklyAdherenceCalculator.compute

    func testComputeEmptyWeek() throws {
        let ctx = try makeMemoryContext()
        let a = WeeklyAdherenceCalculator.compute(for: Date(), context: ctx)
        XCTAssertEqual(a.planned, 0)
        XCTAssertEqual(a.completed, 0)
    }

    func testComputeBucketsByStatus() throws {
        let ctx = try makeMemoryContext()
        // Pick a known date so plan placement is deterministic.
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        var cal = Calendar.current
        cal.firstWeekday = 2
        let weekStart = cal.dateInterval(of: .weekOfYear, for: ref)!.start

        let statuses: [DayPlanStatus] = [.completed, .completed, .missed, .skipped, .scheduled]
        for (i, s) in statuses.enumerated() {
            let day = cal.date(byAdding: .day, value: i, to: weekStart)!
            let plan = DayPlan(date: day, templateId: UUID(), status: s)
            ctx.insert(plan)
        }
        try ctx.save()

        let a = WeeklyAdherenceCalculator.compute(for: ref, context: ctx)
        XCTAssertEqual(a.planned, 5)
        XCTAssertEqual(a.completed, 2)
        XCTAssertEqual(a.missed, 1)
        XCTAssertEqual(a.skipped, 1)
        XCTAssertEqual(a.current, 1) // scheduled
        XCTAssertFalse(a.isFullyCompleted)
    }

    func testComputeIgnoresPlansOutsideWeek() throws {
        let ctx = try makeMemoryContext()
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        var cal = Calendar.current
        cal.firstWeekday = 2
        let weekStart = cal.dateInterval(of: .weekOfYear, for: ref)!.start

        let outsideDay = cal.date(byAdding: .day, value: -3, to: weekStart)!
        let insideDay = cal.date(byAdding: .day, value: 1, to: weekStart)!
        ctx.insert(DayPlan(date: outsideDay, templateId: UUID(), status: .completed))
        ctx.insert(DayPlan(date: insideDay, templateId: UUID(), status: .completed))
        try ctx.save()

        let a = WeeklyAdherenceCalculator.compute(for: ref, context: ctx)
        XCTAssertEqual(a.planned, 1, "Plan from previous week must not be counted")
        XCTAssertEqual(a.completed, 1)
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
