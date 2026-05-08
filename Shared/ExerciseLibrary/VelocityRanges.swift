// VelocityRanges.swift
// VBTrainer · 2026-05
//
// Maps the user's training goal onto a target velocity band per exercise.
// Defaults derive from VL thresholds in Sánchez-Medina (2011) +
// Pareja-Blanco (2017):
//
//   - Power      → narrow upper band (light load, high velocity, VL ~10%)
//   - Strength   → mid band (heavy load, moderate velocity, VL ~20%)
//   - Muscle     → wider mid-low band (moderate load, VL ~30%)
//   - FatLoss    → broad band (varied load, VL ~30-40%)
//   - General    → broad band, similar to fat-loss
//
// These bands are RECOMMENDATIONS shown in the haptic-feedback target
// selector; the user can override per-exercise in settings.

import Foundation

/// Returns the recommended target-velocity band for an exercise given the
/// user's training goal. Falls back to the exercise's static default if
/// the goal is .general.
public func defaultVelocityRange(
    for exercise: Exercise,
    goal: TrainingGoal
) -> ClosedRange<Double> {
    let base = exercise.defaultTargetVelocityRange
    let lo = base.lowerBound
    let hi = base.upperBound
    let mid = (lo + hi) / 2.0
    let span = hi - lo

    switch goal {
    case .power:
        // Narrow upper band — train near 1RM-velocity * 2.5 to ~3x.
        return (hi - span * 0.20)...(hi + span * 0.20)
    case .strength:
        // Mid band, slightly tighter than the static default.
        return (mid - span * 0.30)...(mid + span * 0.30)
    case .muscle:
        // Wider mid-low band, allowing higher VL.
        return (lo - span * 0.10)...(mid + span * 0.20)
    case .fatLoss, .general:
        // Broadest — accept anything within the static default.
        return base
    }
}

/// Returns the recommended VL% ceiling for the given goal, consistent with
/// PRD §8.4.
public func defaultVLCeiling(for goal: TrainingGoal) -> Double {
    switch goal {
    case .power:    return 10
    case .strength: return 20
    case .muscle:   return 30
    case .fatLoss:  return 35
    case .general:  return 25
    }
}
