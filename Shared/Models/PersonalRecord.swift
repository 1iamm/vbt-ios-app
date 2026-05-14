// PersonalRecord.swift
// VBTrainer · 2026-05
//
// Per-exercise PR log. Append-only — when a new record beats an existing
// PR of the same kind, a new row is inserted (preserving history).

import Foundation
import SwiftData

@Model
public final class PersonalRecord {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: String
    public var kindRaw: String
    public var value: Double
    public var achievedAt: Date
    public var sourceWorkoutId: UUID?
    public var sourceJumpTestId: UUID?

    public init(
        id: UUID = UUID(),
        exerciseId: String,
        kind: PRKind,
        value: Double,
        achievedAt: Date = Date(),
        sourceWorkoutId: UUID? = nil,
        sourceJumpTestId: UUID? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        kindRaw = kind.rawValue
        self.value = value
        self.achievedAt = achievedAt
        self.sourceWorkoutId = sourceWorkoutId
        self.sourceJumpTestId = sourceJumpTestId
    }

    public var kind: PRKind {
        get { PRKind(rawValue: kindRaw) ?? .maxWeight }
        set { kindRaw = newValue.rawValue }
    }
}
