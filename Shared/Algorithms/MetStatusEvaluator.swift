// MetStatusEvaluator.swift
// VBTrainer · 2026-05
//
// Pure function mapping a velocity reading and a target band to a
// MetStatus. Drives haptic feedback intensity (PRD §M5).

import Foundation

public enum MetStatusEvaluator {
    /// Borderline window: 5% under target.lowerBound is "borderline", below
    /// that is "failed".
    public static let borderlineMargin: Double = 0.05

    public static func evaluate(
        velocity: Double,
        target: ClosedRange<Double>
    ) -> MetStatus {
        if velocity >= target.upperBound {
            .excellent
        } else if velocity >= target.lowerBound {
            .met
        } else if velocity >= target.lowerBound * (1 - borderlineMargin) {
            .borderline
        } else {
            .failed
        }
    }
}
