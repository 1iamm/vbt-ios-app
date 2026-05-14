// Exercise.swift
// VBTrainer · 2026-05
//
// An exercise is a value type (not a SwiftData model) — exercises are
// constants. The user-editable thing is `Template`/`Workout`, which
// reference an exercise by its kebab-case `id`.

import Foundation

public struct Exercise: Identifiable, Codable, Hashable, Sendable {
    public let id: String // kebab-case, e.g. "back-squat"
    public let nameZH: String // 中文名
    public let nameEN: String // English
    public let category: ExerciseCategory
    public let defaultVelocityVariant: VelocityVariant

    /// 1RM-time velocity in m/s, from literature. Nil for bodyweight or
    /// movements where 1RM is not meaningful (e.g. CMJ).
    public let referenceV1RM: Double?

    /// Default VL% ceiling used as force-stop threshold (PRD §5.4).
    public let defaultVLCeiling: Double

    /// Default target velocity range — used as initial haptic feedback band
    /// before the user adjusts in settings. Resolved per training-goal via
    /// `defaultVelocityRange(for:goal:)`.
    public let defaultTargetVelocityRange: ClosedRange<Double>

    public let isUnilateral: Bool
    public let sfSymbol: String

    /// Citations backing the V1RM and VL defaults for this exercise.
    public let citationIds: [String]

    public let notes: String?

    public init(
        id: String,
        nameZH: String,
        nameEN: String,
        category: ExerciseCategory,
        defaultVelocityVariant: VelocityVariant,
        referenceV1RM: Double?,
        defaultVLCeiling: Double,
        defaultTargetVelocityRange: ClosedRange<Double>,
        isUnilateral: Bool = false,
        sfSymbol: String = "figure.strengthtraining.traditional",
        citationIds: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.nameZH = nameZH
        self.nameEN = nameEN
        self.category = category
        self.defaultVelocityVariant = defaultVelocityVariant
        self.referenceV1RM = referenceV1RM
        self.defaultVLCeiling = defaultVLCeiling
        self.defaultTargetVelocityRange = defaultTargetVelocityRange
        self.isUnilateral = isUnilateral
        self.sfSymbol = sfSymbol
        self.citationIds = citationIds
        self.notes = notes
    }

    public var citations: [PaperCitation] {
        citationIds.compactMap(Citations.byId)
    }
}
