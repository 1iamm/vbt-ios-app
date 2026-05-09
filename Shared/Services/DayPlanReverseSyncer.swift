// DayPlanReverseSyncer.swift
// VBTrainer · 2026-05
//
// Reverse-sync layer: when the user edits a "训练" calendar event in iPhone's
// Calendar app (changes start time, deletes), reconcile the change back into
// the corresponding DayPlan SwiftData record.
//
// V1.5 scope:
//   - Subscribe to EKEventStoreChanged notifications
//   - On change, pull events for the surrounding ±30 days range
//   - For each EventChange:
//       · find DayPlan by eventKitIdentifier
//       · update its date / scheduledTimeMinutes if drift detected
//   - Local DayPlans whose event was deleted in calendar → unschedule
//
// Out of scope: conflict resolution (assume calendar wins for time edits;
// if a workout is already completed, ignore the calendar edit).

import Foundation
import SwiftData

#if canImport(EventKit) && os(iOS)
import EventKit
#endif

@available(iOS 17.0, *)
@MainActor
public final class DayPlanReverseSyncer {

    public static let shared = DayPlanReverseSyncer()

    private var subscriptionToken: Any?
    private var modelContainer: ModelContainer?

    public init() {}

    public func bind(container: ModelContainer) {
        self.modelContainer = container
        // Subscribe once.
        if subscriptionToken == nil {
            subscriptionToken = EventKitService.shared.subscribeToChanges { [weak self] in
                Task { @MainActor in
                    self?.runReconcile()
                }
            }
        }
    }

    /// Run a one-shot reconcile of [-30, +30] days around now.
    public func runReconcile() {
        guard let container = modelContainer else { return }
        guard EventKitService.shared.hasReadAccess else { return }

        let cal = Calendar.current
        let now = Date()
        let lo = cal.date(byAdding: .day, value: -30, to: now) ?? now
        let hi = cal.date(byAdding: .day, value: 30, to: now) ?? now
        let changes = EventKitService.shared.pullChanges(in: lo...hi)
        let context = ModelContext(container)

        // Index DayPlans by eventKitIdentifier
        let lo0 = cal.startOfDay(for: lo)
        let hi0 = cal.startOfDay(for: hi)
        var fd = FetchDescriptor<DayPlan>(
            predicate: #Predicate { $0.date >= lo0 && $0.date < hi0 }
        )
        fd.fetchLimit = 200
        let plans = (try? context.fetch(fd)) ?? []
        let plansByIdent = Dictionary(uniqueKeysWithValues: plans
            .compactMap { p -> (String, DayPlan)? in
                guard let id = p.eventKitIdentifier else { return nil }
                return (id, p)
            })

        let presentIdents = Set(changes.map(\.identifier))

        // 1. Apply edits (time / day) from EventChange → DayPlan
        for change in changes {
            guard let plan = plansByIdent[change.identifier] else { continue }
            if plan.completed { continue } // completed plans aren't auto-edited
            let newDay = cal.startOfDay(for: change.start)
            let newMinutes = cal.component(.hour, from: change.start) * 60
                + cal.component(.minute, from: change.start)
            if !cal.isDate(plan.date, inSameDayAs: newDay) || plan.scheduledTimeMinutes != newMinutes {
                plan.date = newDay
                plan.scheduledTimeMinutes = newMinutes
            }
        }

        // 2. Detect deletions: DayPlans whose stored eventKitIdentifier no
        //    longer appears in the calendar → unschedule (delete the plan).
        for plan in plans where plan.eventKitIdentifier != nil && !plan.completed {
            if !presentIdents.contains(plan.eventKitIdentifier!) {
                context.delete(plan)
            }
        }

        try? context.save()
        NotificationCenter.default.post(name: .vbtDayPlanReverseSynced, object: nil)
    }
}

public extension Notification.Name {
    static let vbtDayPlanReverseSynced = Notification.Name("vbt.dayPlan.reverseSynced")
}
