// ReadinessCalculatorTests.swift
// VBTrainer · 2026-05

import XCTest

final class ReadinessCalculatorTests: XCTestCase {
    func testInsufficientWhenNoBaseline() {
        let input = ReadinessInput(hrv: 50, hrvBaselineMean: nil)
        let output = ReadinessCalculator.compute(input: input)
        XCTAssertNil(output.score)
        XCTAssertEqual(output.tier, .insufficient)
    }

    func testGreenWhenAtBaselineWithGoodSleep() throws {
        let input = ReadinessInput(
            hrv: 50, hrvBaselineMean: 50, hrvBaselineStd: 5,
            rhr: 58, rhrBaselineMean: 58, rhrBaselineStd: 2,
            sleepTotalHours: 7.8, sleepDeepHours: 1.7,
            wristTempDelta: 0.0
        )
        let output = ReadinessCalculator.compute(input: input)
        XCTAssertNotNil(output.score)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(output.score), 80)
        XCTAssertEqual(output.tier, .green)
    }

    func testRedWhenSeverelyBelowBaseline() throws {
        let input = ReadinessInput(
            hrv: 30, hrvBaselineMean: 50, hrvBaselineStd: 5, // -4σ HRV
            rhr: 70, rhrBaselineMean: 58, rhrBaselineStd: 2, // +6σ RHR
            sleepTotalHours: 4.0, sleepDeepHours: 0.5,
            wristTempDelta: 1.5
        )
        let output = ReadinessCalculator.compute(input: input)
        XCTAssertNotNil(output.score)
        XCTAssertLessThan(try XCTUnwrap(output.score), 60)
        XCTAssertEqual(output.tier, .red)
    }

    func testTierMapping() {
        XCTAssertEqual(ReadinessCalculator.tierFromScore(85), .green)
        XCTAssertEqual(ReadinessCalculator.tierFromScore(70), .yellow)
        XCTAssertEqual(ReadinessCalculator.tierFromScore(50), .red)
    }
}
