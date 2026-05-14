// SyntheticMotionGenerator.swift
// VBTrainer · watchOS · 2026-05
//
// Generates synthetic IMU streams for unit-testing the algorithms.
// Models a "rep" as: rest → eccentric (decel down) → bottom → concentric
// (accel up then decel) → top → rest, using a simple sinusoidal velocity
// profile.

import Foundation
import simd

public enum SyntheticMotionGenerator {
    /// Generates a sequence of MotionSamples representing a clean set of N
    /// reps with the given peak concentric velocity and duration profile.
    ///
    /// - Parameters:
    ///   - reps: Number of reps to simulate.
    ///   - peakVelocity: Target peak vertical velocity in m/s during concentric.
    ///   - concentricDuration: How long the concentric phase lasts (s).
    ///   - eccentricDuration: How long the eccentric phase lasts (s).
    ///   - restBetween: Rest between reps (s).
    ///   - hz: Sample rate (default 100).
    ///   - noise: Per-sample white noise σ in m/s² (default 0.05).
    public static func cleanSet(
        reps: Int,
        peakVelocity: Double = 0.6,
        concentricDuration: Double = 0.8,
        eccentricDuration: Double = 1.2,
        restBetween: Double = 1.0,
        hz: Double = 100,
        noise: Double = 0.05
    ) -> [MotionSample] {
        var samples: [MotionSample] = []
        let dt = 1.0 / hz
        var t: Double = 0

        // 1 second of pre-rest so the detector starts from .rest cleanly.
        let preRest = 1.0
        appendStatic(into: &samples, duration: preRest, startTime: t, hz: hz, noise: noise)
        t += preRest

        for _ in 0..<reps {
            // Eccentric (down): negative velocity, half-sine profile
            t = appendHalfSine(
                into: &samples,
                duration: eccentricDuration,
                peakVelocity: -peakVelocity * 0.7, // descent slower than ascent
                startTime: t, hz: hz, noise: noise
            )
            // Bottom dwell
            appendStatic(into: &samples, duration: 0.10, startTime: t, hz: hz, noise: noise)
            t += 0.10
            // Concentric (up): positive half-sine
            t = appendHalfSine(
                into: &samples,
                duration: concentricDuration,
                peakVelocity: peakVelocity,
                startTime: t, hz: hz, noise: noise
            )
            // Top + rest
            appendStatic(into: &samples, duration: restBetween, startTime: t, hz: hz, noise: noise)
            t += restBetween
        }

        return samples
    }

    /// Pure static signal (rest), useful for "no rep should fire" tests.
    public static func staticSignal(
        duration: Double,
        hz: Double = 100,
        noise: Double = 0.05
    ) -> [MotionSample] {
        var samples: [MotionSample] = []
        appendStatic(into: &samples, duration: duration, startTime: 0, hz: hz, noise: noise)
        return samples
    }

    /// Synthesizes a CMJ jump of the requested height using projectile motion.
    /// Reference: Citations.linthorne2001Jump.
    public static func cmjJump(
        heightCm: Double,
        hz: Double = 100,
        noise: Double = 0.05
    ) -> [MotionSample] {
        var samples: [MotionSample] = []
        let dt = 1.0 / hz
        let g = 9.80665
        let h = heightCm / 100.0
        // Flight time t such that h = g·t²/8 → t = sqrt(8h/g)
        let flight = (8 * h / g).squareRoot()

        // 0.5s pre + 0.5s squat-down + takeoff + flight + landing impact + 0.5s post
        var t: Double = 0
        appendStatic(into: &samples, duration: 0.5, startTime: t, hz: hz, noise: noise); t += 0.5

        // Loading phase (negative accel) — quick downward then upward thrust
        let loadDuration = 0.30
        for _ in 0..<Int(loadDuration * hz) {
            samples.append(.synthetic(t: t, az: -0.5 + Self.gauss(noise)))
            t += dt
        }
        // Push-off: large positive accel for ~50ms
        let pushDuration = 0.05
        let pushAccel = 20.0
        for _ in 0..<Int(pushDuration * hz) {
            samples.append(.synthetic(t: t, az: pushAccel + Self.gauss(noise)))
            t += dt
        }
        // Flight (free fall): user accel ≈ 0 (gravity removed)
        let flightSamples = Int(flight * hz)
        for _ in 0..<flightSamples {
            samples.append(.synthetic(t: t, az: 0 + Self.gauss(noise)))
            t += dt
        }
        // Landing impact: large positive spike for ~30ms
        let impactDuration = 0.03
        for _ in 0..<Int(impactDuration * hz) {
            samples.append(.synthetic(t: t, az: 30.0 + Self.gauss(noise)))
            t += dt
        }
        // Post-rest
        appendStatic(into: &samples, duration: 0.5, startTime: t, hz: hz, noise: noise)
        return samples
    }

    // MARK: - Helpers

    private static func appendStatic(
        into samples: inout [MotionSample],
        duration: Double, startTime: Double, hz: Double, noise: Double
    ) {
        let n = Int(duration * hz)
        let dt = 1.0 / hz
        var t = startTime
        for _ in 0..<n {
            samples.append(.synthetic(t: t, az: gauss(noise)))
            t += dt
        }
    }

    /// Appends a half-sine velocity profile, returns the new time cursor.
    /// Acceleration = derivative of velocity = π/T * peak * cos(πt/T).
    private static func appendHalfSine(
        into samples: inout [MotionSample],
        duration: Double, peakVelocity: Double,
        startTime: Double, hz: Double, noise: Double
    ) -> Double {
        let n = Int(duration * hz)
        let dt = 1.0 / hz
        var t = startTime
        let T = duration
        for i in 0..<n {
            let localT = Double(i) * dt
            // d/dt [peak * sin(π·t/T)] = peak * π/T * cos(π·t/T)
            let a = peakVelocity * .pi / T * cos(.pi * localT / T) + gauss(noise)
            samples.append(.synthetic(t: t, az: a))
            t += dt
        }
        return t
    }

    /// Box-Muller-ish small-σ Gaussian noise.
    private static func gauss(_ sigma: Double) -> Double {
        guard sigma > 0 else { return 0 }
        let u1 = Double.random(in: 1e-9...1)
        let u2 = Double.random(in: 0...1)
        let z = (-2 * log(u1)).squareRoot() * cos(2 * .pi * u2)
        return z * sigma
    }
}

public extension MotionSample {
    /// Convenience constructor for synthetic samples — only az matters.
    static func synthetic(t: TimeInterval, az: Double) -> MotionSample {
        MotionSample(
            timestamp: t,
            userAccel: SIMD3(0, 0, az),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
        )
    }
}
