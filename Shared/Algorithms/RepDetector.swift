// RepDetector.swift
// VBTrainer · 2026-05
//
// State-machine rep detector.
//
//     rest ──[a.z < -threshold for ≥ 200ms]──▶ eccentric
//     eccentric ──[v crosses 0 from negative]──▶ bottom
//     bottom ──[a.z > +threshold for ≥ 50ms]──▶ concentric
//     concentric ──[v crosses 0 from positive]──▶ top
//     top ──[|a.z| < rest_threshold for ≥ 200ms]──▶ rest  (rep complete)
//
// Reference: Citations.oReilly2018InertialReview — state-machine approach
// is the established baseline for wearable-IMU rep detection.

import Foundation

public final class RepDetector {

    public enum State: String, Sendable {
        case rest
        case eccentric
        case bottom
        case concentric
        case top
    }

    // MARK: - Tunable thresholds

    public struct Tuning: Sendable {
        public var concentricEntryAccel: Double = 0.8        // m/s², upward
        public var eccentricEntryAccel: Double = -0.6        // m/s², downward
        public var restAccelMagnitude: Double = 0.40         // m/s², "still"
        public var minEccentricDwell: Double = 0.20          // s
        public var minConcentricDwell: Double = 0.20         // s
        public var minBottomDwell: Double = 0.05             // s
        public var minTopDwell: Double = 0.10                // s
        public var minRestForCompletion: Double = 0.20       // s

        public init() {}
    }

    public private(set) var state: State = .rest
    public private(set) var repCount: Int = 0

    /// Closure called with each completed rep event (concentric span only).
    public var onRepCompleted: ((RepEvent) -> Void)?

    /// Closure called when state machine enters .rest — caller (e.g.
    /// VelocityCalculator) can use this to apply ZUPT.
    public var onEnterRest: (() -> Void)?

    // MARK: - State

    private let tuning: Tuning
    private var velocityCalc = VelocityCalculator()

    private var stateEnteredAt: TimeInterval = 0
    private var concentricStart: TimeInterval = 0
    private var concentricEnd: TimeInterval = 0
    private var lastVelocity: Double = 0
    private var lastSampleTime: TimeInterval = 0

    public init(tuning: Tuning = Tuning()) {
        self.tuning = tuning
    }

    public func reset() {
        state = .rest
        repCount = 0
        velocityCalc.reset()
        stateEnteredAt = 0
        concentricStart = 0
        concentricEnd = 0
        lastVelocity = 0
        lastSampleTime = 0
    }

    /// Feed one sample (call at sample rate, e.g. 100Hz).
    public func ingest(_ sample: MotionSample) {
        let t = sample.timestamp
        let a = sample.verticalAccel
        velocityCalc.integrate(timestamp: t, accel: a)
        let v = velocityCalc.velocity
        let dwell = t - stateEnteredAt

        switch state {
        case .rest:
            if a < tuning.eccentricEntryAccel && dwell > 0.05 {
                transition(to: .eccentric, at: t)
            }

        case .eccentric:
            // Eccentric → bottom on velocity zero-crossing from negative,
            // after the minimum dwell.
            if dwell >= tuning.minEccentricDwell && lastVelocity < 0 && v >= 0 {
                transition(to: .bottom, at: t)
            }

        case .bottom:
            // Bottom → concentric when upward acceleration kicks in.
            if dwell >= tuning.minBottomDwell && a > tuning.concentricEntryAccel {
                concentricStart = t
                transition(to: .concentric, at: t)
            }
            // If we somehow drift back into eccentric (false bottom), abort.
            if dwell > 1.0 && a < tuning.eccentricEntryAccel {
                transition(to: .eccentric, at: t)
            }

        case .concentric:
            // Concentric → top on velocity zero-crossing from positive.
            if dwell >= tuning.minConcentricDwell && lastVelocity > 0 && v <= 0 {
                concentricEnd = t
                transition(to: .top, at: t)
            }

        case .top:
            // Top → rest when motion settles.
            if dwell >= tuning.minTopDwell && abs(a) < tuning.restAccelMagnitude {
                // The rep is complete only after sustained rest.
                if dwell >= tuning.minTopDwell + tuning.minRestForCompletion {
                    finalizeRep(at: t)
                }
            }
            // If user starts the next rep before resting, also count it.
            if dwell >= tuning.minTopDwell && a < tuning.eccentricEntryAccel {
                finalizeRep(at: t)
                transition(to: .eccentric, at: t)
            }
        }

        lastVelocity = v
        lastSampleTime = t
    }

    // MARK: - Internals

    private func transition(to newState: State, at t: TimeInterval) {
        state = newState
        stateEnteredAt = t
        if newState == .rest {
            velocityCalc.applyZUPT()
            onEnterRest?()
        }
    }

    private func finalizeRep(at t: TimeInterval) {
        guard concentricEnd > concentricStart else {
            transition(to: .rest, at: t)
            return
        }
        repCount += 1
        let stats = velocityCalc.stats(from: concentricStart, to: concentricEnd)
            ?? VelocityStats(meanVelocity: 0, peakVelocity: 0, meanPropulsiveVelocity: 0, duration: 0)
        let event = RepEvent(
            index: repCount,
            startTimestamp: concentricStart,
            endTimestamp: concentricEnd,
            meanVelocity: stats.meanVelocity,
            peakVelocity: stats.peakVelocity,
            meanPropulsiveVelocity: stats.meanPropulsiveVelocity,
            concentricDuration: stats.duration
        )
        onRepCompleted?(event)
        transition(to: .rest, at: t)
    }
}
