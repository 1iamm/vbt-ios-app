// MetStatusEvaluatorTests.swift
// VBTrainer · 2026-05

import XCTest

final class MetStatusEvaluatorTests: XCTestCase {

    let target: ClosedRange<Double> = 0.55...0.70

    func testExcellentAtUpperBound() {
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.70, target: target), .excellent)
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.85, target: target), .excellent)
    }

    func testMetInsideRange() {
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.62, target: target), .met)
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.55, target: target), .met)
    }

    func testBorderlineWithin5Percent() {
        // 0.95 × 0.55 = 0.5225 → values in [0.5225, 0.55) are borderline
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.53, target: target), .borderline)
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.5225, target: target), .borderline)
    }

    func testFailedBelow5Percent() {
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.50, target: target), .failed)
        XCTAssertEqual(MetStatusEvaluator.evaluate(velocity: 0.10, target: target), .failed)
    }
}
