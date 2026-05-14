// DayPlanStateMachineTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0 — PR-T2 (part 1). Coverage for DayPlanStateMachine,
// the single funnel for every DayPlan status transition. Refactor risk:
// the verbs are called from Today / Plan / Calendar / Timeline / AI
// engine / reverse syncer — a regression here silently shows wrong dot
// colors / banner state for an indefinite period.
//
// Coverage matrix:
//   markCompleted()       — scheduled → completed (with workoutId link)
//   markCompleted()       — inProgress → completed
//   markCompleted()       — already completed = no-op (preserve link)
//   markCompleted()       — no matching plan = nil return
//   markInProgress()      — scheduled → inProgress
//   markInProgress()      — only fires from scheduled (idempotent on other)
//   markSkipped()         — scheduled → skipped
//   markSkipped()         — refuses to demote completed
//   reconcileMissed()     — past + scheduled → missed
//   reconcileMissed()     — leaves today's scheduled alone
//   reconcileMissed()     — leaves past + completed alone
//   backfillLegacyCompleted() — completed=true + statusRaw=scheduled → status=completed

import SwiftData
import XCTest

@MainActor
final class DayPlanStateMachineTests: XCTestCase {
    // MARK: - markCompleted

    func testMarkCompletedTransitionsScheduledPlan() throws {
        let ctx = try makeMemoryContext()
        let day = Calendar.current.startOfDay(for: Date())
        let plan = DayPlan(date: day, templateId: UUID(), status: .scheduled)
        ctx.insert(plan)
        try ctx.save()

        let workoutId = UUID()
        let result = DayPlanStateMachine.markCompleted(
            for: workoutId,
            workoutDay: day,
            in: ctx
        )
        XCTAssertEqual(result?.id, plan.id)
        XCTAssertEqual(plan.status, .completed)
        XCTAssertEqual(plan.completedWorkoutId, workoutId)
        XCTAssertTrue(plan.completed)
    }

    func testMarkCompletedTransitionsInProgressPlan() throws {
        let ctx = try makeMemoryContext()
        let day = Calendar.current.startOfDay(for: Date())
        let plan = DayPlan(date: day, templateId: UUID(), status: .inProgress)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.markCompleted(for: UUID(), workoutDay: day, in: ctx)
        XCTAssertEqual(plan.status, .completed)
    }

    func testMarkCompletedDoesNotOverwriteAlreadyCompleted() throws {
        let ctx = try makeMemoryContext()
        let day = Calendar.current.startOfDay(for: Date())
        let originalWorkoutId = UUID()
        let plan = DayPlan(
            date: day,
            templateId: UUID(),
            completed: true,
            completedWorkoutId: originalWorkoutId,
            status: .completed
        )
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.markCompleted(for: UUID(), workoutDay: day, in: ctx)
        XCTAssertEqual(plan.completedWorkoutId, originalWorkoutId, "Existing link must not be overwritten")
    }

    func testMarkCompletedReturnsNilWhenNoMatchingPlan() throws {
        let ctx = try makeMemoryContext()
        let result = DayPlanStateMachine.markCompleted(
            for: UUID(),
            workoutDay: Date(),
            in: ctx
        )
        XCTAssertNil(result)
    }

    // MARK: - markInProgress

    func testMarkInProgressTransitionsScheduledPlan() throws {
        let ctx = try makeMemoryContext()
        let plan = DayPlan(date: Date(), templateId: UUID(), status: .scheduled)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.markInProgress(planId: plan.id, in: ctx)
        XCTAssertEqual(plan.status, .inProgress)
    }

    func testMarkInProgressDoesNotDemoteCompleted() throws {
        let ctx = try makeMemoryContext()
        let plan = DayPlan(date: Date(), templateId: UUID(), status: .completed)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.markInProgress(planId: plan.id, in: ctx)
        XCTAssertEqual(plan.status, .completed, "Completed must not regress")
    }

    // MARK: - markSkipped

    func testMarkSkippedTransitionsScheduled() throws {
        let ctx = try makeMemoryContext()
        let plan = DayPlan(date: Date(), templateId: UUID(), status: .scheduled)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.markSkipped(planId: plan.id, in: ctx)
        XCTAssertEqual(plan.status, .skipped)
    }

    func testMarkSkippedRefusesToDemoteCompleted() throws {
        let ctx = try makeMemoryContext()
        let plan = DayPlan(date: Date(), templateId: UUID(), status: .completed)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.markSkipped(planId: plan.id, in: ctx)
        XCTAssertEqual(plan.status, .completed, "Completed must not be skipped after the fact")
    }

    // MARK: - reconcileMissed

    func testReconcileMissedMarksPastScheduled() throws {
        let ctx = try makeMemoryContext()
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(cal.date(byAdding: .day, value: -1, to: now))
        let plan = DayPlan(date: yesterday, templateId: UUID(), status: .scheduled)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.reconcileMissed(now: now, in: ctx)
        XCTAssertEqual(plan.status, .missed)
    }

    func testReconcileMissedLeavesTodayAlone() throws {
        let ctx = try makeMemoryContext()
        let now = Calendar.current.startOfDay(for: Date())
        let plan = DayPlan(date: now, templateId: UUID(), status: .scheduled)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.reconcileMissed(now: now, in: ctx)
        XCTAssertEqual(plan.status, .scheduled, "Today's plan must stay scheduled")
    }

    func testReconcileMissedLeavesCompletedAlone() throws {
        let ctx = try makeMemoryContext()
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(cal.date(byAdding: .day, value: -1, to: now))
        let plan = DayPlan(date: yesterday, templateId: UUID(), status: .completed)
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.reconcileMissed(now: now, in: ctx)
        XCTAssertEqual(plan.status, .completed)
    }

    // MARK: - backfillLegacyCompleted

    func testBackfillLegacyCompleted() throws {
        let ctx = try makeMemoryContext()
        let plan = DayPlan(
            date: Date(),
            templateId: UUID(),
            completed: true, // legacy
            status: .scheduled // statusRaw lags
        )
        // Force-reset statusRaw because init() sets it via `status:` param.
        plan.statusRaw = DayPlanStatus.scheduled.rawValue
        ctx.insert(plan)
        try ctx.save()

        DayPlanStateMachine.backfillLegacyCompleted(in: ctx)
        XCTAssertEqual(plan.status, .completed, "Legacy completed=true must back-fill to .completed")
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
