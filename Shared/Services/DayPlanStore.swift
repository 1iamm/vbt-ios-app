// DayPlanStore.swift
// VBTrainer · 2026-05
//
// CRUD over DayPlan + queries used by Today / Weekly Planner / History.

import Foundation
import SwiftData

@available(iOS 17.0, watchOS 10.0, *)
public enum DayPlanStore {
    /// All DayPlans within a date range (inclusive of from, exclusive of to).
    @MainActor
    public static func plans(in range: Range<Date>, context: ModelContext) -> [DayPlan] {
        let lo = Calendar.current.startOfDay(for: range.lowerBound)
        let hi = Calendar.current.startOfDay(for: range.upperBound)
        var fd = FetchDescriptor<DayPlan>(
            predicate: #Predicate { $0.date >= lo && $0.date < hi },
            sortBy: [SortDescriptor(\.date)]
        )
        fd.fetchLimit = 200
        return (try? context.fetch(fd)) ?? []
    }

    @MainActor
    public static func plan(on day: Date, context: ModelContext) -> DayPlan? {
        let start = Calendar.current.startOfDay(for: day)
        var fd = FetchDescriptor<DayPlan>(predicate: #Predicate { $0.date == start })
        fd.fetchLimit = 1
        return (try? context.fetch(fd))?.first
    }

    @MainActor
    @discardableResult
    public static func schedule(
        templateId: UUID,
        on day: Date,
        timeMinutes: Int = 7 * 60 + 30,
        context: ModelContext
    ) -> DayPlan {
        if let existing = plan(on: day, context: context) {
            existing.templateId = templateId
            existing.scheduledTimeMinutes = timeMinutes
            try? context.save()
            return existing
        }
        let plan = DayPlan(date: day, templateId: templateId, scheduledTimeMinutes: timeMinutes)
        context.insert(plan)
        try? context.save()
        return plan
    }

    @MainActor
    public static func unschedule(on day: Date, context: ModelContext) {
        guard let plan = plan(on: day, context: context) else { return }
        context.delete(plan)
        try? context.save()
    }

    @MainActor
    public static func today(context: ModelContext) -> DayPlan? {
        plan(on: Date(), context: context)
    }
}
