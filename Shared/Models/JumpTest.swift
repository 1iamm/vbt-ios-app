// JumpTest.swift
// VBTrainer · 2026-05
//
// CMJ (Counter-Movement Jump) test — independent from Workout per PRD §M2.2.
// Used for daily neuromuscular state assessment; can optionally link to
// the Workout it was performed before.
//
// Reference: Citations.claudino2017CMJ, Citations.watkins2017CMJReadiness.

import Foundation
import SwiftData

@Model
public final class JumpTest {
    @Attribute(.unique) public var id: UUID
    public var performedAt: Date

    /// Per-attempt jump heights in centimeters (best-effort policy: take 3).
    public var attempts: [Double]

    /// Per-attempt flight times in seconds (used for height computation).
    /// Reference: Citations.linthorne2001Jump — height = g·t² / 8 (flight time method).
    public var flightTimeSeconds: [Double]

    public var bestHeightCm: Double
    public var linkedWorkoutId: UUID?

    public init(
        id: UUID = UUID(),
        performedAt: Date = Date(),
        attempts: [Double] = [],
        flightTimeSeconds: [Double] = [],
        linkedWorkoutId: UUID? = nil
    ) {
        self.id = id
        self.performedAt = performedAt
        self.attempts = attempts
        self.flightTimeSeconds = flightTimeSeconds
        bestHeightCm = attempts.max() ?? 0
        self.linkedWorkoutId = linkedWorkoutId
    }

    /// Recomputes `bestHeightCm` from `attempts`. Call after mutating attempts.
    public func recomputeBest() {
        bestHeightCm = attempts.max() ?? 0
    }
}
