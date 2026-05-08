// LVPCalculator.swift
// VBTrainer · 2026-05
//
// Load-velocity profile (LVP) least-squares regression and e1RM estimation.
//
// References:
//   - Citations.jidovtseff2011LVP — load-velocity for 1RM prediction
//   - Citations.garciaRamos2018LVPVariants

import Foundation

public struct LVPFit: Sendable, Equatable {
    public let slope: Double      // a in v = a·load + b
    public let intercept: Double  // b
    public let r2: Double         // coefficient of determination
    public let pointCount: Int

    public init(slope: Double, intercept: Double, r2: Double, pointCount: Int) {
        self.slope = slope
        self.intercept = intercept
        self.r2 = r2
        self.pointCount = pointCount
    }
}

public enum LVPCalculator {

    /// Minimum number of distinct loads required to compute a meaningful LVP.
    /// Reference: Citations.jidovtseff2011LVP — 4-5 points typical; we use 5
    /// as a more conservative threshold.
    public static let minDistinctLoads = 5

    /// Fits v = a·load + b given a list of (load, velocity) points.
    /// Returns nil when fewer than `minDistinctLoads` distinct loads are present.
    public static func fit(points: [(load: Double, velocity: Double)]) -> LVPFit? {
        let distinctLoads = Set(points.map { round($0.load * 100) / 100 })
        guard distinctLoads.count >= minDistinctLoads else { return nil }
        guard points.count >= minDistinctLoads else { return nil }

        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.load }
        let sumY = points.reduce(0) { $0 + $1.velocity }
        let sumXY = points.reduce(0) { $0 + $1.load * $1.velocity }
        let sumXX = points.reduce(0) { $0 + $1.load * $1.load }

        let denom = n * sumXX - sumX * sumX
        guard abs(denom) > 1e-9 else { return nil }
        let a = (n * sumXY - sumX * sumY) / denom
        let b = (sumY - a * sumX) / n

        // R²
        let meanY = sumY / n
        var ssTot: Double = 0
        var ssRes: Double = 0
        for p in points {
            let predicted = a * p.load + b
            ssRes += pow(p.velocity - predicted, 2)
            ssTot += pow(p.velocity - meanY, 2)
        }
        let r2 = ssTot > 0 ? 1.0 - ssRes / ssTot : 0

        return LVPFit(slope: a, intercept: b, r2: r2, pointCount: points.count)
    }

    /// Estimated 1RM = (v1RM - b) / a. Returns nil for non-negative slope.
    public static func estimate1RM(fit: LVPFit, v1RM: Double) -> Double? {
        guard fit.slope < 0 else { return nil }
        let result = (v1RM - fit.intercept) / fit.slope
        guard result.isFinite, result > 0 else { return nil }
        return result
    }

    /// Convenience: collect distinct (load, velocity) points from a list of
    /// workouts for the same exercise. Uses MV by default unless overridden.
    public static func points(
        from workouts: [Workout],
        variant: VelocityVariant = .mv
    ) -> [(load: Double, velocity: Double)] {
        var pts: [(Double, Double)] = []
        for w in workouts {
            for s in w.sets where !s.reps.isEmpty {
                let firstRep = s.reps.sorted(by: { $0.index < $1.index }).first!
                let v = firstRep.velocity(for: variant)
                pts.append((s.weightKg, v))
            }
        }
        return pts
    }
}
