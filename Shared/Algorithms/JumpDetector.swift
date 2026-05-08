// JumpDetector.swift
// VBTrainer · 2026-05
//
// Counter-Movement Jump detection via flight-time method.
//
// References:
//   - Citations.linthorne2001Jump (h = g·t²/8 derivation)
//   - Citations.claudino2017CMJ (CMJ as neuromuscular monitoring tool)
//   - Citations.watkins2017CMJReadiness

import Foundation

public final class JumpDetector {

    public struct JumpResult: Sendable, Equatable {
        public let heightCm: Double
        public let flightTimeSeconds: Double
        public let takeoffTimestamp: TimeInterval
        public let landingTimestamp: TimeInterval
    }

    public struct Tuning: Sendable {
        /// |userAccel.z| below this for ≥ minFlightDuration → flight
        public var freeFallAccelThreshold: Double = 1.5      // m/s²
        public var landingImpactThreshold: Double = 15.0     // m/s² (≈ 1.5g over removed gravity)
        public var minFlightDuration: Double = 0.10          // s — under this is noise
        public var maxFlightDuration: Double = 1.20          // s — over this is unrealistic

        public init() {}
    }

    public private(set) var attempts: [JumpResult] = []
    public var bestHeightCm: Double { attempts.map(\.heightCm).max() ?? 0 }

    public var onJump: ((JumpResult) -> Void)?

    private let tuning: Tuning

    private enum Phase { case onGround, inFlight }
    private var phase: Phase = .onGround
    private var freeFallStartedAt: TimeInterval?

    public init(tuning: Tuning = Tuning()) {
        self.tuning = tuning
    }

    public func reset() {
        attempts.removeAll()
        phase = .onGround
        freeFallStartedAt = nil
    }

    public func ingest(_ sample: MotionSample) {
        let a = sample.verticalAccel
        let mag = abs(a)
        let t = sample.timestamp

        switch phase {
        case .onGround:
            // Detect entry into free-fall: low acceleration magnitude.
            if mag < tuning.freeFallAccelThreshold {
                if freeFallStartedAt == nil {
                    freeFallStartedAt = t
                }
                // Once in free-fall for the minimum duration, flag as in-flight.
                if let s = freeFallStartedAt, t - s > tuning.minFlightDuration {
                    phase = .inFlight
                    freeFallStartedAt = s   // keep takeoff time
                }
            } else {
                freeFallStartedAt = nil
            }

        case .inFlight:
            // Detect landing: large positive acceleration spike.
            if a > tuning.landingImpactThreshold {
                let takeoff = freeFallStartedAt ?? t
                let flight = t - takeoff
                if flight >= tuning.minFlightDuration && flight <= tuning.maxFlightDuration {
                    let g = 9.80665
                    let height_m = g * flight * flight / 8.0
                    let result = JumpResult(
                        heightCm: height_m * 100.0,
                        flightTimeSeconds: flight,
                        takeoffTimestamp: takeoff,
                        landingTimestamp: t
                    )
                    attempts.append(result)
                    onJump?(result)
                }
                phase = .onGround
                freeFallStartedAt = nil
            }
        }
    }
}
