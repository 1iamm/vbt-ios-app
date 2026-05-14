// DayPlanStateMachine.swift
// VBTrainer · 2026-05
//
// Centralised state transitions for DayPlan. Replaces ad-hoc inference
// scattered across Today / Plan / Calendar / Timeline / AI engine / reverse
// syncer. Every status change goes through one of the verbs here.

import Foundation
import SwiftData

@available(iOS 17.0, watchOS 10.0, *)
public enum DayPlanStateMachine {
    // MARK: - Forward transitions (driven by training events)

    /// Called by iPhoneConnectivityService after a WorkoutSnapshot has been
    /// persisted. If the workout's day matches a DayPlan and the plan is in
    /// scheduled / inProgress, mark it completed and link the workout id.
    @MainActor
    @discardableResult
    public static func markCompleted(
        for workoutId: UUID,
        workoutDay: Date,
        in context: ModelContext
    ) -> DayPlan? {
        let cal = Calendar.current
        let day = cal.startOfDay(for: workoutDay)
        var fd = FetchDescriptor<DayPlan>(predicate: #Predicate { $0.date == day })
        fd.fetchLimit = 1
        guard let plan = (try? context.fetch(fd))?.first else { return nil }
        guard plan.status == .scheduled || plan.status == .inProgress else { return plan }
        plan.status = .completed
        plan.completedWorkoutId = workoutId
        try? context.save()
        DayPlanEventBus.shared.publish(.completed(planId: plan.id, workoutId: workoutId))
        return plan
    }

    /// Called when the Watch starts an in-progress training session against
    /// today's plan. Optional convenience — banner might already render
    /// correctly without this transition.
    @MainActor
    public static func markInProgress(planId: UUID, in context: ModelContext) {
        var fd = FetchDescriptor<DayPlan>(predicate: #Predicate { $0.id == planId })
        fd.fetchLimit = 1
        guard let plan = (try? context.fetch(fd))?.first else { return }
        guard plan.status == .scheduled else { return }
        plan.status = .inProgress
        try? context.save()
        DayPlanEventBus.shared.publish(.inProgress(planId: plan.id))
    }

    /// Called when the user explicitly cancels the day's plan or deletes the
    /// linked iPhone Calendar event.
    @MainActor
    public static func markSkipped(planId: UUID, in context: ModelContext) {
        var fd = FetchDescriptor<DayPlan>(predicate: #Predicate { $0.id == planId })
        fd.fetchLimit = 1
        guard let plan = (try? context.fetch(fd))?.first else { return }
        guard plan.status != .completed else { return } // never demote a completed plan
        plan.status = .skipped
        try? context.save()
        DayPlanEventBus.shared.publish(.skipped(planId: plan.id))
    }

    // MARK: - Reconciliation

    /// Called on app launch and whenever the day rolls over. Any plan whose
    /// `date` is in the past and whose status is still `.scheduled` becomes
    /// `.missed`. Idempotent.
    @MainActor
    public static func reconcileMissed(
        now: Date = Date(),
        in context: ModelContext
    ) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        var fd = FetchDescriptor<DayPlan>(
            predicate: #Predicate { $0.date < today && $0.statusRaw == "scheduled" }
        )
        fd.fetchLimit = 100
        let stale = (try? context.fetch(fd)) ?? []
        guard !stale.isEmpty else { return }
        let ids = stale.map(\.id)
        for plan in stale {
            plan.status = .missed
        }
        try? context.save()
        DayPlanEventBus.shared.publish(.missed(planIds: ids))
    }

    /// Backfill: existing DayPlans created before status was introduced have
    /// `statusRaw` defaulting to "scheduled". For old plans whose `completed`
    /// boolean is already true (impossible under current code, but defensive),
    /// migrate to .completed; for old plans on past dates, leave them as
    /// scheduled — `reconcileMissed` will push them to .missed on next launch.
    @MainActor
    public static func backfillLegacyCompleted(in context: ModelContext) {
        var fd = FetchDescriptor<DayPlan>(predicate: #Predicate {
            $0.completed == true && $0.statusRaw == "scheduled"
        })
        fd.fetchLimit = 200
        let needs = (try? context.fetch(fd)) ?? []
        for plan in needs {
            plan.statusRaw = DayPlanStatus.completed.rawValue
            plan.statusUpdatedAt = Date()
        }
        if !needs.isEmpty { try? context.save() }
    }
}
