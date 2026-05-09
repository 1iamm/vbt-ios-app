// WeeklyAdherence.swift
// VBTrainer · 2026-05
//
// Aggregates DayPlan status into a per-week summary used by:
//   - TodayHeader's "本周 N/M" mini row
//   - StatsView's narrative line ("本周比上周多 X 训")
//   - CompletionFeedbackCoordinator's "周满训" celebration trigger
//
// One source of truth — UI / Stats / Celebrations all consume the same struct.

import Foundation
import SwiftData

public struct WeeklyAdherence: Sendable, Equatable {
    public var weekStart: Date
    public var weekEnd: Date
    public var planned: Int      // total scheduled (any status)
    public var completed: Int
    public var skipped: Int
    public var missed: Int
    public var inProgress: Int
    public var current: Int      // still scheduled & today/future

    public var completionRate: Double {
        guard planned > 0 else { return 0 }
        return Double(completed) / Double(planned)
    }

    /// True when the week has at least one planned day and all of them are
    /// completed. Drives the "本周满训" celebration.
    public var isFullyCompleted: Bool {
        planned > 0 && completed == planned
    }
}

@available(iOS 17.0, watchOS 10.0, *)
public enum WeeklyAdherenceCalculator {

    @MainActor
    public static func compute(
        for reference: Date = Date(),
        context: ModelContext
    ) -> WeeklyAdherence {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday

        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: reference)?.start,
              let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else {
            return .init(weekStart: reference, weekEnd: reference,
                         planned: 0, completed: 0, skipped: 0, missed: 0,
                         inProgress: 0, current: 0)
        }

        var fd = FetchDescriptor<DayPlan>(
            predicate: #Predicate { $0.date >= weekStart && $0.date < weekEnd }
        )
        fd.fetchLimit = 14
        let plans = (try? context.fetch(fd)) ?? []

        var c = WeeklyAdherence(weekStart: weekStart, weekEnd: weekEnd,
                                planned: plans.count, completed: 0, skipped: 0,
                                missed: 0, inProgress: 0, current: 0)
        for p in plans {
            switch p.status {
            case .completed:  c.completed += 1
            case .skipped:    c.skipped += 1
            case .missed:     c.missed += 1
            case .inProgress: c.inProgress += 1
            case .scheduled:  c.current += 1
            }
        }
        return c
    }

    /// Continuous streak (in days) of completed DayPlans ending today or
    /// yesterday. Counts back from the most recent completed day; one missed
    /// day breaks the streak.
    @MainActor
    public static func currentStreak(
        now: Date = Date(),
        context: ModelContext
    ) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let earliest = cal.date(byAdding: .day, value: -120, to: today) ?? today
        var fd = FetchDescriptor<DayPlan>(
            predicate: #Predicate { $0.date <= today && $0.date >= earliest },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        fd.fetchLimit = 120
        let plans = (try? context.fetch(fd)) ?? []
        let byDay = Dictionary(uniqueKeysWithValues: plans.map { (cal.startOfDay(for: $0.date), $0.status) })

        var streak = 0
        var cursor = today
        while true {
            let s = byDay[cursor]
            if s == .completed {
                streak += 1
            } else if s == .missed || s == .skipped {
                break
            } else {
                // No plan that day — neutral, doesn't extend or break (rest day)
                if streak == 0, cal.isDate(cursor, inSameDayAs: today) {
                    // today is plan-less; look back further from yesterday
                } else if streak == 0 {
                    break
                }
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
            if cursor < earliest { break }
        }
        return streak
    }
}
