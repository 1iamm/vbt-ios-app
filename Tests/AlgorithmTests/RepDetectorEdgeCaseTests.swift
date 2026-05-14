// RepDetectorEdgeCaseTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0 — PR-T4 (part 2). Boundary tests on top of the existing
// happy-path RepDetectorTests.swift. RepDetector is the algorithmic core
// — wrong rep count + wrong velocity = useless app.

import XCTest

final class RepDetectorEdgeCaseTests: XCTestCase {
    /// reset() must zero the rep counter AND drop transient state — feeding
    /// a fresh clean set after a reset must produce the same count as a
    /// brand-new detector.
    func testResetClearsRepCounterAndAllowsReuse() {
        let det = RepDetector()
        var capturedReps: [Int] = []
        det.onRepCompleted = { capturedReps.append($0.index) }

        let firstSet = SyntheticMotionGenerator.cleanSet(
            reps: 3,
            peakVelocity: 0.7,
            restBetween: 2.0
        )
        for s in firstSet { det.ingest(s) }
        let firstCount = det.repCount

        det.reset()
        capturedReps.removeAll()
        XCTAssertEqual(det.repCount, 0)
        XCTAssertEqual(det.state, .rest)

        let secondSet = SyntheticMotionGenerator.cleanSet(
            reps: 3,
            peakVelocity: 0.7,
            restBetween: 2.0
        )
        for s in secondSet { det.ingest(s) }

        XCTAssertEqual(det.repCount, firstCount, "Reset detector must produce same rep count for identical input")
        // Index sequence resets to 1.
        XCTAssertEqual(capturedReps.first, 1)
    }

    /// onEnterRest must fire each time the state machine transitions into
    /// .rest — used by callers to apply ZUPT correction.
    func testOnEnterRestFiresPerRep() {
        let det = RepDetector()
        var restCount = 0
        det.onEnterRest = { restCount += 1 }

        let set = SyntheticMotionGenerator.cleanSet(
            reps: 4,
            peakVelocity: 0.7,
            restBetween: 2.0
        )
        for s in set { det.ingest(s) }

        // At least one rest event per completed rep. The pre-rest period
        // doesn't fire onEnterRest (already in .rest at init).
        XCTAssertGreaterThanOrEqual(restCount, det.repCount)
    }

    /// Static signal (no motion) must produce zero reps regardless of
    /// duration — used to be a regression vector for over-eager detectors.
    func testStaticSignalProducesZeroReps() {
        let det = RepDetector()
        let static5s = SyntheticMotionGenerator.staticSignal(duration: 5.0)
        for s in static5s { det.ingest(s) }
        XCTAssertEqual(det.repCount, 0)
        XCTAssertEqual(det.state, .rest)
    }

    /// Custom tuning is honoured — bumping the thresholds high enough must
    /// reject a signal the default tuning would accept.
    func testCustomTuningCanRejectCleanReps() {
        var tuning = RepDetector.Tuning()
        tuning.concentricEntryAccel = 10.0 // unreachable upward accel
        tuning.eccentricEntryAccel = -10.0 // unreachable downward accel
        let det = RepDetector(tuning: tuning)

        let set = SyntheticMotionGenerator.cleanSet(
            reps: 3,
            peakVelocity: 0.7,
            restBetween: 2.0
        )
        for s in set { det.ingest(s) }
        XCTAssertEqual(det.repCount, 0, "Unreachable thresholds must produce zero reps")
    }
}
