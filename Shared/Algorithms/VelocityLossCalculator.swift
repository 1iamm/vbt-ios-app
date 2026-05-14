// VelocityLossCalculator.swift
// VBTrainer · 2026-05
//
// Velocity-loss percentage and force-stop logic.
//
// Reference: Citations.sanchezMedina2011VL — VL = (V_first - V_current) / V_first × 100.
// Reference: Citations.parejaBlanco2017VLEffects — VL thresholds drive adaptation profiles.

import Foundation

public struct VelocityLossCalculator {
    public private(set) var firstRep: RepEvent?
    public let variant: VelocityVariant

    public init(variant: VelocityVariant) {
        self.variant = variant
    }

    /// Records the first rep so subsequent reps can be compared against it.
    public mutating func record(rep: RepEvent) {
        if firstRep == nil {
            firstRep = rep
        }
    }

    /// Computes VL% for the given rep relative to the first rep in the set.
    /// Returns 0 when the current rep is the first or velocities are degenerate.
    public func velocityLoss(for rep: RepEvent) -> Double {
        guard let base = firstRep, base.index != rep.index else { return 0 }
        let v0 = base.velocity(for: variant)
        let v = rep.velocity(for: variant)
        guard v0 > 0 else { return 0 }
        return max(0, (v0 - v) / v0 * 100.0)
    }

    /// Resets for a new set.
    public mutating func reset() {
        firstRep = nil
    }
}

public enum VelocityLossPolicy {
    /// Returns true if VL exceeds the configured ceiling — UI then surfaces
    /// the force-stop screen (PRD §M5).
    public static func shouldForceStop(vl: Double, ceiling: Double) -> Bool {
        vl > ceiling
    }
}
