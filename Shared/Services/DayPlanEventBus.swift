// DayPlanEventBus.swift
// VBTrainer · 2026-05
//
// AsyncStream of DayPlan lifecycle events. Round 2 of the priority-flow
// roadmap depends on a single subscribable signal that downstream consumers
// (CompletionFeedbackCoordinator, Stats narratives, future AI replay)
// can react to without each maintaining their own status-inference logic.

import Foundation

public enum DayPlanEvent: Sendable {
    /// Plan entered .completed; payload = workout id (nil if completed by
    /// other means, e.g. legacy backfill).
    case completed(planId: UUID, workoutId: UUID?)
    case inProgress(planId: UUID)
    case skipped(planId: UUID)
    case missed(planIds: [UUID])
}

@available(iOS 17.0, watchOS 10.0, *)
public final class DayPlanEventBus: @unchecked Sendable {
    public static let shared = DayPlanEventBus()

    public var stream: AsyncStream<DayPlanEvent> {
        _stream
    }

    private let _stream: AsyncStream<DayPlanEvent>
    private let continuation: AsyncStream<DayPlanEvent>.Continuation

    public init() {
        var c: AsyncStream<DayPlanEvent>.Continuation!
        _stream = AsyncStream(bufferingPolicy: .bufferingNewest(32)) { c = $0 }
        continuation = c
    }

    public func publish(_ event: DayPlanEvent) {
        continuation.yield(event)
    }
}
