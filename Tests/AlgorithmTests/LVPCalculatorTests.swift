// LVPCalculatorTests.swift
// VBTrainer · 2026-05

import XCTest

final class LVPCalculatorTests: XCTestCase {
    func testInsufficientLoadsReturnsNil() {
        let pts: [(Double, Double)] = [(60, 0.8), (70, 0.7), (80, 0.6), (90, 0.5)] // 4 loads
        XCTAssertNil(LVPCalculator.fit(points: pts.map { (load: $0.0, velocity: $0.1) }))
    }

    func testPerfectLinearFit() {
        // v = -0.005 × load + 1.1
        let loads: [Double] = [60, 70, 80, 90, 100]
        let velocities = loads.map { -0.005 * $0 + 1.1 }
        let pts = zip(loads, velocities).map { (load: $0.0, velocity: $0.1) }
        let fit = LVPCalculator.fit(points: pts)
        XCTAssertNotNil(fit)
        if let f = fit {
            XCTAssertEqual(f.slope, -0.005, accuracy: 1e-6)
            XCTAssertEqual(f.intercept, 1.1, accuracy: 1e-6)
            XCTAssertEqual(f.r2, 1.0, accuracy: 1e-6)
        }
    }

    func testEstimate1RM() throws {
        let loads: [Double] = [60, 70, 80, 90, 100]
        let velocities = loads.map { -0.005 * $0 + 1.1 } // straight line
        let pts = zip(loads, velocities).map { (load: $0.0, velocity: $0.1) }
        let fit = try XCTUnwrap(LVPCalculator.fit(points: pts))
        // V1RM = 0.30 → 1RM = (0.30 - 1.1) / -0.005 = 160 kg (not reasonable
        // physically but math-correct for this synthetic line)
        let e1rm = LVPCalculator.estimate1RM(fit: fit, v1RM: 0.30)
        XCTAssertNotNil(e1rm)
        XCTAssertEqual(try XCTUnwrap(e1rm), 160.0, accuracy: 0.5)
    }

    func testNonNegativeSlopeReturnsNil() throws {
        // Synthetic positive slope (impossible for real LVP) — should reject
        let pts: [(Double, Double)] = [(60, 0.1), (70, 0.2), (80, 0.3), (90, 0.4), (100, 0.5)]
        let fit = try XCTUnwrap(LVPCalculator.fit(points: pts.map { (load: $0.0, velocity: $0.1) }))
        XCTAssertNil(LVPCalculator.estimate1RM(fit: fit, v1RM: 0.30))
    }
}
