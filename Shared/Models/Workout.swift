// Workout.swift
// VBTrainer · 2026-05
//
// One training session. Owns its sets via cascade relationship.
// `exerciseId` is a string FK into the static `exerciseLibrary` array
// (Exercise is a value type, not a SwiftData model — exercises are
// constants, not user data).

import Foundation
import SwiftData

@Model
public final class Workout {
    @Attribute(.unique) public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var exerciseId: String
    public var notes: String?
    public var rpe: Int? // 1-10, subjective rating
    public var linkedTemplateId: UUID?
    public var readinessSnapshotId: UUID?

    /// Source of the workout — `.watch` for Watch-driven IMU sessions,
    /// `.iPhone` for iPhone-only manual logging. Optional + nil-default so
    /// pre-V2.x rows (which were always Watch-driven) decode cleanly.
    public var sourceRaw: String?

    /// JSON-encoded `[HeartRateSample]`. Stored as Data because SwiftData's
    /// support for arrays of structs is fragile across schema migrations.
    public var heartRateSamplesData: Data?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workout)
    public var sets: [WorkoutSet] = []

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        exerciseId: String,
        notes: String? = nil,
        rpe: Int? = nil,
        linkedTemplateId: UUID? = nil,
        readinessSnapshotId: UUID? = nil,
        source: WorkoutSource = .watch
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exerciseId = exerciseId
        self.notes = notes
        self.rpe = rpe
        self.linkedTemplateId = linkedTemplateId
        self.readinessSnapshotId = readinessSnapshotId
        sourceRaw = source.rawValue
    }

    public var source: WorkoutSource {
        get { WorkoutSource(rawValue: sourceRaw ?? "") ?? .watch }
        set { sourceRaw = newValue.rawValue }
    }

    // MARK: - Derived

    public var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps.count }
    }

    public var totalVolumeKg: Double {
        sets.reduce(0) { $0 + $1.weightKg * Double($1.reps.count) }
    }

    public var durationSeconds: TimeInterval {
        guard let end = endedAt else { return 0 }
        return end.timeIntervalSince(startedAt)
    }
}
