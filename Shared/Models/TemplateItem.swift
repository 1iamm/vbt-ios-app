// TemplateItem.swift
// VBTrainer · 2026-05
//
// One exercise entry within a Template. References an exerciseId from the
// static library.

import Foundation
import SwiftData

@Model
public final class TemplateItem {
    @Attribute(.unique) public var id: UUID
    public var index: Int
    public var exerciseId: String
    public var targetSets: Int
    public var targetReps: Int
    public var targetWeightKg: Double?
    public var targetVelocityMin: Double?
    public var targetVelocityMax: Double?
    public var vlCeiling: Double?
    public var restSeconds: Int
    public var sideRaw: String

    public var template: Template?

    @Relationship(deleteRule: .cascade, inverse: \TemplateSetSpec.item)
    public var setSpecs: [TemplateSetSpec] = []

    public init(
        id: UUID = UUID(),
        index: Int,
        exerciseId: String,
        targetSets: Int = 3,
        targetReps: Int = 5,
        targetWeightKg: Double? = nil,
        targetVelocityRange: ClosedRange<Double>? = nil,
        vlCeiling: Double? = nil,
        restSeconds: Int = 90,
        side: Side = .both
    ) {
        self.id = id
        self.index = index
        self.exerciseId = exerciseId
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        targetVelocityMin = targetVelocityRange?.lowerBound
        targetVelocityMax = targetVelocityRange?.upperBound
        self.vlCeiling = vlCeiling
        self.restSeconds = restSeconds
        sideRaw = side.rawValue
    }

    public var side: Side {
        get { Side(rawValue: sideRaw) ?? .both }
        set { sideRaw = newValue.rawValue }
    }

    public var targetVelocityRange: ClosedRange<Double>? {
        guard let lo = targetVelocityMin, let hi = targetVelocityMax, lo <= hi else { return nil }
        return lo...hi
    }

    /// True iff the user has planned individual sets (otherwise the legacy
    /// `targetSets × targetReps @ targetWeightKg` is used).
    public var hasPerSetSpecs: Bool {
        !setSpecs.isEmpty
    }

    public var orderedSetSpecs: [TemplateSetSpec] {
        setSpecs.sorted { $0.index < $1.index }
    }

    /// Effective work-set parameters for legacy consumers (Watch sync).
    /// Falls back to top-level fields when no per-set specs exist.
    public var primaryWorkWeightKg: Double? {
        if let firstWork = orderedSetSpecs.first(where: { $0.kind == .work }) {
            return firstWork.weightKg
        }
        return targetWeightKg
    }

    public var effectiveWorkSetCount: Int {
        if hasPerSetSpecs {
            return orderedSetSpecs.filter { $0.kind == .work }.count
        }
        return targetSets
    }
}
