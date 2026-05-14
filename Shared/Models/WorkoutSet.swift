// WorkoutSet.swift
// VBTrainer · 2026-05
//
// One set within a Workout. Class is named `WorkoutSet` (not `ExerciseSet`)
// to avoid collision with Swift's `Set` collection type — otherwise SwiftUI
// previews and code completion get confused.

import Foundation
import SwiftData

@Model
public final class WorkoutSet {
    @Attribute(.unique) public var id: UUID
    public var index: Int // 1-based order within the workout
    public var weightKg: Double
    public var targetReps: Int?
    public var restAfterSeconds: Int
    public var sideRaw: String // Side enum
    public var velocityVariantRaw: String // VelocityVariant enum

    // Optional target band for haptic feedback during the set.
    // Stored as two doubles since SwiftData can't model ClosedRange directly.
    public var targetVelocityMin: Double?
    public var targetVelocityMax: Double?

    public var vlCeiling: Double? // %, force-stop threshold

    public var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \Rep.set)
    public var reps: [Rep] = []

    public init(
        id: UUID = UUID(),
        index: Int,
        weightKg: Double,
        targetReps: Int? = nil,
        restAfterSeconds: Int = 90,
        side: Side = .both,
        velocityVariant: VelocityVariant = .mv,
        targetVelocityRange: ClosedRange<Double>? = nil,
        vlCeiling: Double? = nil
    ) {
        self.id = id
        self.index = index
        self.weightKg = weightKg
        self.targetReps = targetReps
        self.restAfterSeconds = restAfterSeconds
        sideRaw = side.rawValue
        velocityVariantRaw = velocityVariant.rawValue
        targetVelocityMin = targetVelocityRange?.lowerBound
        targetVelocityMax = targetVelocityRange?.upperBound
        self.vlCeiling = vlCeiling
    }

    public var side: Side {
        get { Side(rawValue: sideRaw) ?? .both }
        set { sideRaw = newValue.rawValue }
    }

    public var velocityVariant: VelocityVariant {
        get { VelocityVariant(rawValue: velocityVariantRaw) ?? .mv }
        set { velocityVariantRaw = newValue.rawValue }
    }

    public var targetVelocityRange: ClosedRange<Double>? {
        guard let lo = targetVelocityMin, let hi = targetVelocityMax, lo <= hi else { return nil }
        return lo...hi
    }

    // MARK: - Derived

    /// Mean velocity across reps using the configured variant.
    public var avgVelocity: Double {
        guard !reps.isEmpty else { return 0 }
        let values = reps.map { rep in
            switch velocityVariant {
            case .mv: rep.meanVelocity
            case .mpv: rep.meanPropulsiveVelocity ?? rep.meanVelocity
            case .pv: rep.peakVelocity
            }
        }
        return values.reduce(0, +) / Double(values.count)
    }

    public var peakVelocity: Double {
        reps.map(\.peakVelocity).max() ?? 0
    }

    /// Velocity loss percentage based on first vs last rep using the
    /// configured velocity variant.
    /// Reference: Citations.sanchezMedina2011VL — VL = (V_first - V_last) / V_first * 100.
    public var velocityLossPercent: Double {
        guard reps.count >= 2 else { return 0 }
        let first: Double
        let last: Double
        switch velocityVariant {
        case .mv:
            first = reps.first?.meanVelocity ?? 0
            last = reps.last?.meanVelocity ?? 0
        case .mpv:
            first = reps.first?.meanPropulsiveVelocity ?? reps.first?.meanVelocity ?? 0
            last = reps.last?.meanPropulsiveVelocity ?? reps.last?.meanVelocity ?? 0
        case .pv:
            first = reps.first?.peakVelocity ?? 0
            last = reps.last?.peakVelocity ?? 0
        }
        guard first > 0 else { return 0 }
        return max(0, (first - last) / first * 100.0)
    }
}
