// VelocityLossTests.swift
// VBTrainer · 2026-05

import XCTest

final class VelocityLossTests: XCTestCase {

    private func makeRep(index: Int, mv: Double) -> RepEvent {
        RepEvent(
            index: index,
            startTimestamp: Double(index),
            endTimestamp: Double(index) + 1,
            meanVelocity: mv,
            peakVelocity: mv * 1.2,
            meanPropulsiveVelocity: mv * 1.05,
            concentricDuration: 1.0
        )
    }

    func testFormulaMatchesPaper() {
        var calc = VelocityLossCalculator(variant: .mv)
        let velocities = [0.62, 0.60, 0.58, 0.55, 0.52, 0.49]
        var reps: [RepEvent] = []
        for (i, v) in velocities.enumerated() {
            let r = makeRep(index: i + 1, mv: v)
            calc.record(rep: r)
            reps.append(r)
        }

        let expected = velocities.map { (0.62 - $0) / 0.62 * 100.0 }
        for (i, rep) in reps.enumerated() {
            XCTAssertEqual(calc.velocityLoss(for: rep), expected[i], accuracy: 0.001)
        }
    }

    func testForceStopAboveCeiling() {
        XCTAssertTrue(VelocityLossPolicy.shouldForceStop(vl: 32, ceiling: 30))
        XCTAssertFalse(VelocityLossPolicy.shouldForceStop(vl: 28, ceiling: 30))
        XCTAssertFalse(VelocityLossPolicy.shouldForceStop(vl: 30, ceiling: 30))
    }

    func testReset() {
        var calc = VelocityLossCalculator(variant: .mv)
        let r1 = makeRep(index: 1, mv: 0.6)
        calc.record(rep: r1)
        calc.reset()
        XCTAssertNil(calc.firstRep)
    }

    func testNonNegative() {
        var calc = VelocityLossCalculator(variant: .mv)
        let r1 = makeRep(index: 1, mv: 0.5)
        let r2 = makeRep(index: 2, mv: 0.7)   // velocity GAIN — VL should clamp to 0
        calc.record(rep: r1)
        XCTAssertEqual(calc.velocityLoss(for: r2), 0)
    }
}
