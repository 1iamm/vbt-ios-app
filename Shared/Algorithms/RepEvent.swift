// RepEvent.swift
// VBTrainer · 2026-05
//
// One detected repetition. Pure value type — emitted by RepDetector,
// consumed by ActiveWorkoutSession to build set summaries.

import Foundation

public struct RepEvent: Sendable, Equatable {
    public let index: Int // 1-based, within the current set
    public let startTimestamp: TimeInterval // when concentric began
    public let endTimestamp: TimeInterval // when concentric ended (top reached)
    public let meanVelocity: Double // m/s, MV (concentric only)
    public let peakVelocity: Double // m/s, PV
    public let meanPropulsiveVelocity: Double // m/s, MPV (propulsive sub-phase)
    public let concentricDuration: Double // s

    public init(
        index: Int,
        startTimestamp: TimeInterval,
        endTimestamp: TimeInterval,
        meanVelocity: Double,
        peakVelocity: Double,
        meanPropulsiveVelocity: Double,
        concentricDuration: Double
    ) {
        self.index = index
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.meanVelocity = meanVelocity
        self.peakVelocity = peakVelocity
        self.meanPropulsiveVelocity = meanPropulsiveVelocity
        self.concentricDuration = concentricDuration
    }

    public func velocity(for variant: VelocityVariant) -> Double {
        switch variant {
        case .mv: meanVelocity
        case .mpv: meanPropulsiveVelocity
        case .pv: peakVelocity
        }
    }
}
