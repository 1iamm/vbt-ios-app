// ReadinessStore.swift
// VBTrainer · 2026-05

import Foundation
import SwiftData

@available(iOS 17.0, watchOS 10.0, *)
public enum ReadinessStore {
    /// Inserts or replaces the snapshot for the given calendar day.
    public static func upsert(
        _ snapshot: ReadinessSnapshot,
        in context: ModelContext
    ) {
        let day = Calendar.current.startOfDay(for: snapshot.date)
        let next = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day
        let descriptor = FetchDescriptor<ReadinessSnapshot>(
            predicate: #Predicate<ReadinessSnapshot> {
                $0.date >= day && $0.date < next
            }
        )
        if let existing = try? context.fetch(descriptor) {
            for old in existing {
                context.delete(old)
            }
        }
        snapshot.date = day
        context.insert(snapshot)
        try? context.save()
    }

    public static func latest(in context: ModelContext) -> ReadinessSnapshot? {
        let descriptor = FetchDescriptor<ReadinessSnapshot>(
            sortBy: [SortDescriptor(\ReadinessSnapshot.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    public static func forDay(_ day: Date, in context: ModelContext) -> ReadinessSnapshot? {
        let dayStart = Calendar.current.startOfDay(for: day)
        let next = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let descriptor = FetchDescriptor<ReadinessSnapshot>(
            predicate: #Predicate<ReadinessSnapshot> {
                $0.date >= dayStart && $0.date < next
            }
        )
        return (try? context.fetch(descriptor))?.first
    }

    public static func recent(days: Int, in context: ModelContext) -> [ReadinessSnapshot] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<ReadinessSnapshot>(
            predicate: #Predicate<ReadinessSnapshot> { $0.date >= cutoff },
            sortBy: [SortDescriptor(\ReadinessSnapshot.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
