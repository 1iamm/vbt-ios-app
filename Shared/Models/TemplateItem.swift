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
        self.targetVelocityMin = targetVelocityRange?.lowerBound
        self.targetVelocityMax = targetVelocityRange?.upperBound
        self.vlCeiling = vlCeiling
        self.restSeconds = restSeconds
        self.sideRaw = side.rawValue
    }

    public var side: Side {
        get { Side(rawValue: sideRaw) ?? .both }
        set { sideRaw = newValue.rawValue }
    }

    public var targetVelocityRange: ClosedRange<Double>? {
        guard let lo = targetVelocityMin, let hi = targetVelocityMax, lo <= hi else { return nil }
        return lo...hi
    }
}
