// VelocityCalculator.swift
// VBTrainer · 2026-05
//
// Trapezoidal integration of vertical acceleration with ZUPT correction.
//
// References:
//   - Citations.skog2010ZUPT (Zero-velocity detection algorithm evaluation)
//   - Citations.foxlin2005Pedestrian (ZUPT theory for IMU pedestrian tracking)
//   - Citations.sanchezMedina2010Propulsive (MV / MPV / PV variant rationale)

import Foundation

public struct VelocityCalculator {

    /// Internal velocity state (m/s) along the integration axis.
    public private(set) var velocity: Double = 0

    /// Ring of (timestamp, velocity, acceleration) — used to compute MV/PV/MPV
    /// over a window (e.g. the concentric phase of a rep).
    public private(set) var samples: [(t: TimeInterval, v: Double, a: Double)] = []

    private var lastTimestamp: TimeInterval?
    private var lastAcceleration: Double = 0

    public init() {}

    /// Integrate one sample. Returns the new velocity.
    @discardableResult
    public mutating func integrate(timestamp: TimeInterval, accel: Double) -> Double {
        defer {
            lastTimestamp = timestamp
            lastAcceleration = accel
        }
        guard let prev = lastTimestamp else {
            // First sample: no integration possible yet.
            samples.append((timestamp, velocity, accel))
            return velocity
        }
        let dt = max(0, timestamp - prev)
        // Trapezoidal: v_{t+1} = v_t + (a_{t-1} + a_t)/2 * dt
        let dv = (lastAcceleration + accel) / 2.0 * dt
        velocity += dv
        samples.append((timestamp, velocity, accel))
        return velocity
    }

    /// ZUPT — hard reset velocity to 0. Call when the rep state machine
    /// enters .rest. Reference: Skog 2010 §III ("zero-velocity update").
    public mutating func applyZUPT() {
        velocity = 0
        // Don't clear samples — they survive ZUPT for stats summary.
    }

    /// Reset everything (new set).
    public mutating func reset() {
        velocity = 0
        samples.removeAll(keepingCapacity: true)
        lastTimestamp = nil
        lastAcceleration = 0
    }

    /// Compute velocity statistics over a sub-window (e.g. concentric phase).
    /// Returns nil if window is empty.
    public func stats(
        from start: TimeInterval,
        to end: TimeInterval
    ) -> VelocityStats? {
        let window = samples.filter { $0.t >= start && $0.t <= end }
        guard !window.isEmpty else { return nil }

        let velocities = window.map(\.v)
        let absVels = velocities.map { abs($0) }
        let meanV = absVels.reduce(0, +) / Double(absVels.count)
        let peakV = absVels.max() ?? 0

        // Propulsive sub-phase: where acceleration > 0 (still pushing)
        let propulsive = window.filter { $0.a > 0 }
        let mpv: Double
        if propulsive.isEmpty {
            mpv = meanV   // fallback
        } else {
            let propVels = propulsive.map { abs($0.v) }
            mpv = propVels.reduce(0, +) / Double(propVels.count)
        }

        return VelocityStats(
            meanVelocity: meanV,
            peakVelocity: peakV,
            meanPropulsiveVelocity: mpv,
            duration: end - start
        )
    }
}

public struct VelocityStats: Sendable, Equatable {
    public let meanVelocity: Double
    public let peakVelocity: Double
    public let meanPropulsiveVelocity: Double
    public let duration: Double
}
