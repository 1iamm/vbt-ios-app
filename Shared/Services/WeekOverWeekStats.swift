// WeekOverWeekStats.swift
// VBTrainer · 2026-05
//
// Computes "this week vs last week" headline numbers used by the Stats tab:
//   - total volume (kg)
//   - average MV across all reps
//   - average VL%
//   - workout count
// Each metric reports the current week's value, previous week's value, and
// percent delta. UI labels positive volume / count deltas as good (green) and
// negative MV deltas as bad. VL% delta direction is context-dependent.

import Foundation
import SwiftData

public struct WeekOverWeekHeadline: Sendable {
    public var thisWeekVolume: Double = 0
    public var lastWeekVolume: Double = 0
    public var thisWeekAvgVelocity: Double = 0
    public var lastWeekAvgVelocity: Double = 0
    public var thisWeekAvgVL: Double = 0
    public var lastWeekAvgVL: Double = 0
    public var thisWeekCount: Int = 0
    public var lastWeekCount: Int = 0

    public func deltaPercent(_ this: Double, _ last: Double) -> Double {
        guard last > 0 else { return this > 0 ? 100 : 0 }
        return (this - last) / last * 100
    }
}

@available(iOS 17.0, watchOS 10.0, *)
public enum WeekOverWeekStats {
    @MainActor
    public static func headline(now: Date = Date(), context: ModelContext) -> WeekOverWeekHeadline {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday — matches design

        guard let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start,
              let lastWeekStart = cal.date(byAdding: .day, value: -7, to: thisWeekStart),
              let thisWeekEnd = cal.date(byAdding: .day, value: 7, to: thisWeekStart) else { return .init() }

        let lo = lastWeekStart
        let hi = thisWeekEnd
        var fd = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.startedAt >= lo && $0.startedAt < hi }
        )
        fd.fetchLimit = 200
        let all = (try? context.fetch(fd)) ?? []

        let thisWeek = all.filter { $0.startedAt >= thisWeekStart }
        let lastWeek = all.filter { $0.startedAt < thisWeekStart }

        var h = WeekOverWeekHeadline()
        h.thisWeekVolume = thisWeek.reduce(0) { $0 + $1.totalVolumeKg }
        h.lastWeekVolume = lastWeek.reduce(0) { $0 + $1.totalVolumeKg }
        h.thisWeekCount = thisWeek.count
        h.lastWeekCount = lastWeek.count

        h.thisWeekAvgVelocity = avgVelocity(thisWeek)
        h.lastWeekAvgVelocity = avgVelocity(lastWeek)
        h.thisWeekAvgVL = avgVL(thisWeek)
        h.lastWeekAvgVL = avgVL(lastWeek)
        return h
    }

    private static func avgVelocity(_ workouts: [Workout]) -> Double {
        let reps = workouts.flatMap { $0.sets.flatMap(\.reps) }
        guard !reps.isEmpty else { return 0 }
        return reps.map(\.meanVelocity).reduce(0, +) / Double(reps.count)
    }

    private static func avgVL(_ workouts: [Workout]) -> Double {
        let perSet = workouts.flatMap { $0.sets.map(\.velocityLossPercent) }
            .filter { $0 > 0 }
        guard !perSet.isEmpty else { return 0 }
        return perSet.reduce(0, +) / Double(perSet.count)
    }
}
