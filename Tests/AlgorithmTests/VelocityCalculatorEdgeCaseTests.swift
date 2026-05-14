// VelocityCalculatorEdgeCaseTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0 — PR-T4 (part 1). Edge-case coverage that the original
// VelocityCalculatorTests.swift only sketches the happy path for.
// `VelocityCalculator` is the foundation of every per-rep velocity number
// the user sees — a silent regression in its boundary behavior breaks
// the entire VBT thesis.

import XCTest

final class VelocityCalculatorEdgeCaseTests: XCTestCase {
    /// First sample has no previous timestamp — integration must return 0
    /// without crashing or producing NaN.
    func testFirstSampleReturnsZero() {
        var calc = VelocityCalculator()
        let v = calc.integrate(timestamp: 100.0, accel: 9.81)
        XCTAssertEqual(v, 0, accuracy: 1e-9)
        XCTAssertEqual(calc.samples.count, 1)
    }

    /// Negative acceleration must drive velocity negative (eccentric phase).
    func testNegativeAccelerationProducesNegativeVelocity() {
        var calc = VelocityCalculator()
        let dt = 0.01
        for i in 0...100 {
            calc.integrate(timestamp: Double(i) * dt, accel: -1.0)
        }
        XCTAssertEqual(calc.velocity, -1.0, accuracy: 0.01)
    }

    /// Non-monotonic timestamps must not produce negative dt → divergent v.
    func testNonMonotonicTimestampsClampedToZero() {
        var calc = VelocityCalculator()
        calc.integrate(timestamp: 1.0, accel: 1.0)
        let v0 = calc.velocity
        // Now feed an out-of-order older timestamp.
        calc.integrate(timestamp: 0.5, accel: 1.0)
        // dt was clamped, no change to velocity beyond float noise.
        XCTAssertEqual(calc.velocity, v0, accuracy: 1e-9)
    }

    /// ZUPT must not erase the historical samples ring (used for stats).
    func testZUPTPreservesSamplesRing() {
        var calc = VelocityCalculator()
        for i in 0...20 {
            calc.integrate(timestamp: Double(i) * 0.01, accel: 1.0)
        }
        let countBefore = calc.samples.count
        calc.applyZUPT()
        XCTAssertEqual(calc.samples.count, countBefore, "ZUPT must NOT clear samples")
        XCTAssertEqual(calc.velocity, 0)
    }

    /// stats() on an empty window returns nil (no false-zero report).
    func testStatsOnEmptyWindowReturnsNil() {
        var calc = VelocityCalculator()
        for i in 0...10 {
            calc.integrate(timestamp: Double(i) * 0.01, accel: 1.0)
        }
        // Query a window past the last sample.
        let s = calc.stats(from: 100, to: 200)
        XCTAssertNil(s)
    }

    /// stats() falls back to meanVelocity for MPV when no propulsive
    /// samples exist (all accel ≤ 0).
    func testStatsAllNegativeAccelFallsBackToMeanForMPV() throws {
        var calc = VelocityCalculator()
        let dt = 0.01
        // 50 samples of negative accel — purely eccentric "rep".
        for i in 0...50 {
            calc.integrate(timestamp: Double(i) * dt, accel: -0.5)
        }
        let s = try XCTUnwrap(calc.stats(from: 0, to: 0.5))
        // MPV must equal meanVelocity (the fallback), not zero.
        XCTAssertEqual(s.meanPropulsiveVelocity, s.meanVelocity, accuracy: 1e-9)
    }

    /// reset() must clear velocity, samples, and the integration anchor —
    /// next integrate() should behave like a brand-new instance.
    func testResetFullyClears() {
        var calc = VelocityCalculator()
        calc.integrate(timestamp: 1.0, accel: 1.0)
        calc.integrate(timestamp: 1.01, accel: 1.0)
        calc.reset()
        XCTAssertEqual(calc.velocity, 0)
        XCTAssertTrue(calc.samples.isEmpty)
        // Anchor must be cleared: next integrate returns 0 like first sample.
        let v = calc.integrate(timestamp: 5.0, accel: 1.0)
        XCTAssertEqual(v, 0, "After reset(), first integrate must behave like new instance")
    }
}
