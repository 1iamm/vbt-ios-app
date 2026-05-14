// JumpTestStore.swift
// VBTrainer · 2026-05

import Foundation
import SwiftData

@available(iOS 17.0, watchOS 10.0, *)
public enum JumpTestStore {
    @discardableResult
    public static func save(
        attempts: [Double],
        flightTimes: [Double] = [],
        linkedWorkoutId: UUID? = nil,
        in context: ModelContext
    ) -> JumpTest {
        let test = JumpTest(
            attempts: attempts,
            flightTimeSeconds: flightTimes,
            linkedWorkoutId: linkedWorkoutId
        )
        context.insert(test)
        try? context.save()
        return test
    }

    public static func latest(in context: ModelContext) -> JumpTest? {
        let descriptor = FetchDescriptor<JumpTest>(
            sortBy: [SortDescriptor(\JumpTest.performedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    public static func recent(within days: Int, in context: ModelContext) -> [JumpTest] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<JumpTest>(
            predicate: #Predicate<JumpTest> { $0.performedAt >= cutoff },
            sortBy: [SortDescriptor(\JumpTest.performedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
