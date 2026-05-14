// JumpDetectorTests.swift
// VBTrainer · 2026-05

import XCTest

final class JumpDetectorTests: XCTestCase {
    func testSyntheticThirtyCmJump() {
        let detector = JumpDetector()
        let signal = SyntheticMotionGenerator.cmjJump(heightCm: 30, noise: 0.02)
        for s in signal {
            detector.ingest(s)
        }

        XCTAssertGreaterThanOrEqual(detector.attempts.count, 1)
        if let result = detector.attempts.first {
            // ±3cm tolerance on synthetic data
            XCTAssertEqual(result.heightCm, 30.0, accuracy: 3.0)
        }
    }

    func testBestOfThree() {
        let detector = JumpDetector()
        for height in [28.0, 31.0, 29.0] {
            let signal = SyntheticMotionGenerator.cmjJump(heightCm: height, noise: 0.02)
            for s in signal {
                detector.ingest(s)
            }
        }
        XCTAssertGreaterThanOrEqual(detector.attempts.count, 3)
        XCTAssertEqual(detector.bestHeightCm, detector.attempts.map(\.heightCm).max() ?? 0)
    }

    func testStaticSignalProducesNoJump() {
        let detector = JumpDetector()
        let signal = SyntheticMotionGenerator.staticSignal(duration: 5, noise: 0.05)
        for s in signal {
            detector.ingest(s)
        }
        XCTAssertEqual(detector.attempts.count, 0)
    }

    func testReset() {
        let detector = JumpDetector()
        let signal = SyntheticMotionGenerator.cmjJump(heightCm: 25, noise: 0.02)
        for s in signal {
            detector.ingest(s)
        }
        detector.reset()
        XCTAssertEqual(detector.attempts.count, 0)
        XCTAssertEqual(detector.bestHeightCm, 0)
    }
}
