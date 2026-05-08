// VelocityCalculatorTests.swift
// VBTrainer · 2026-05

import XCTest

final class VelocityCalculatorTests: XCTestCase {

    func testConstantAccelerationProducesLinearVelocity() {
        var calc = VelocityCalculator()
        let dt = 1.0 / 100.0
        let a = 1.0   // m/s²
        for i in 0...100 {
            calc.integrate(timestamp: Double(i) * dt, accel: a)
        }
        // After 1s of 1 m/s² acceleration, velocity should be ≈ 1.0 m/s.
        XCTAssertEqual(calc.velocity, 1.0, accuracy: 0.01)
    }

    func testZUPTZeroesVelocity() {
        var calc = VelocityCalculator()
        let dt = 1.0 / 100.0
        for i in 0...50 {
            calc.integrate(timestamp: Double(i) * dt, accel: 1.0)
        }
        XCTAssertGreaterThan(calc.velocity, 0)
        calc.applyZUPT()
        XCTAssertEqual(calc.velocity, 0, accuracy: 1e-9)
    }

    func testReset() {
        var calc = VelocityCalculator()
        for i in 0...20 {
            calc.integrate(timestamp: Double(i) * 0.01, accel: 1.0)
        }
        calc.reset()
        XCTAssertEqual(calc.velocity, 0)
        XCTAssertTrue(calc.samples.isEmpty)
    }

    func testStatsOverWindow() {
        // Synthesize: 0.5s ramp up to 0.5 m/s, hold 0.5s, then ramp back.
        var calc = VelocityCalculator()
        let hz: Double = 100
        let dt = 1.0 / hz

        var t = 0.0
        // Ramp up: a = 1 m/s² for 0.5s → reaches 0.5 m/s
        for _ in 0..<Int(0.5 * hz) {
            calc.integrate(timestamp: t, accel: 1.0)
            t += dt
        }
        // Hold at constant velocity (a ≈ 0)
        for _ in 0..<Int(0.5 * hz) {
            calc.integrate(timestamp: t, accel: 0.0)
            t += dt
        }
        // Ramp down: a = -1 m/s² for 0.5s → back to 0
        for _ in 0..<Int(0.5 * hz) {
            calc.integrate(timestamp: t, accel: -1.0)
            t += dt
        }

        let stats = calc.stats(from: 0, to: t)
        XCTAssertNotNil(stats)
        let s = stats!
        XCTAssertEqual(s.peakVelocity, 0.5, accuracy: 0.05)
        XCTAssertGreaterThan(s.meanVelocity, 0)
    }
}
