// LiveWorkoutControllerVLTests.swift
// VBTrainer · 2026-05
//
// Verifies that LiveWorkoutController turns the actor's
// .vlCeilingExceeded event into a NotificationCenter post that the
// V2 navigation host can listen for.

import XCTest

@MainActor
final class LiveWorkoutControllerVLTests: XCTestCase {
    func testVLCeilingExceededPostsNotification() async {
        let controller = LiveWorkoutController()
        let exp = expectation(description: "vbtVLCeilingExceeded posted")
        var receivedVL: Double = 0
        var receivedThreshold: Double = 0
        let token = NotificationCenter.default.addObserver(
            forName: .vbtVLCeilingExceeded, object: nil, queue: .main
        ) { note in
            receivedVL = note.userInfo?["vl"] as? Double ?? -1
            receivedThreshold = note.userInfo?["threshold"] as? Double ?? -1
            exp.fulfill()
        }

        controller.apply(.vlCeilingExceeded(currentVL: 0.42, ceiling: 0.30))

        await fulfillment(of: [exp], timeout: 1.0)
        NotificationCenter.default.removeObserver(token)

        XCTAssertEqual(receivedVL, 0.42, accuracy: 0.001)
        XCTAssertEqual(receivedThreshold, 0.30, accuracy: 0.001)
    }

    func testRepCompletedDoesNotPostVLNotification() async {
        let controller = LiveWorkoutController()
        var fired = false
        let token = NotificationCenter.default.addObserver(
            forName: .vbtVLCeilingExceeded, object: nil, queue: .main
        ) { _ in fired = true }

        let rep = RepEvent(
            index: 1,
            startTimestamp: 0,
            endTimestamp: 1,
            meanVelocity: 0.55,
            peakVelocity: 0.9,
            meanPropulsiveVelocity: 0.6,
            concentricDuration: 0.6
        )
        controller.apply(.repCompleted(rep, .met))

        try? await Task.sleep(nanoseconds: 100_000_000)
        NotificationCenter.default.removeObserver(token)
        XCTAssertFalse(fired, "rep events must not trigger VL notification")
    }
}
