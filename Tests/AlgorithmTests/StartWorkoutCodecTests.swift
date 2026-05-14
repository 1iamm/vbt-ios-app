// StartWorkoutCodecTests.swift
// VBTrainer · 2026-05
//
// Round-trip coverage for the V2 `.startWorkout` ConnectivityMessage. Also
// re-exercises the existing `.template` round-trip so the new enum case
// doesn't accidentally break decoding of older messages.

import XCTest

final class StartWorkoutCodecTests: XCTestCase {
    func testStartWorkoutMessageRoundTrips() throws {
        let original = try ConnectivityMessage.startWorkout(
            StartWorkoutSnapshot(
                templateId: XCTUnwrap(UUID(uuidString: "11111111-2222-3333-4444-555555555555")),
                startItemIndex: 2
            )
        )
        let userInfo = try ConnectivityCodec.encode(original)
        let decoded = try ConnectivityCodec.decode(userInfo)
        XCTAssertEqual(decoded, original)
    }

    func testStartWorkoutDefaultStartIndex() throws {
        let original = ConnectivityMessage.startWorkout(
            StartWorkoutSnapshot(templateId: UUID())
        )
        let userInfo = try ConnectivityCodec.encode(original)
        let decoded = try ConnectivityCodec.decode(userInfo)
        if case let .startWorkout(snap) = decoded {
            XCTAssertEqual(snap.startItemIndex, 0)
            XCTAssertNil(snap.template)
        } else {
            XCTFail("decoded message not .startWorkout")
        }
    }

    func testStartWorkoutBundledTemplateRoundTrips() throws {
        let templateId = UUID()
        let item = TemplateItemSnapshot(
            id: UUID(),
            index: 0,
            exerciseId: "back-squat",
            targetSets: 3,
            targetReps: 5,
            targetWeightKg: 100,
            targetVelocityMin: 0.5,
            targetVelocityMax: 0.7,
            vlCeiling: 0.20,
            restSeconds: 120,
            sideRaw: "both",
            setSpecs: []
        )
        let template = TemplateSnapshot(
            id: templateId,
            name: "Strength A",
            scheduledDate: Date(timeIntervalSince1970: 1_700_000_000),
            items: [item]
        )
        let original = ConnectivityMessage.startWorkout(
            StartWorkoutSnapshot(
                templateId: templateId,
                startItemIndex: 0,
                template: template
            )
        )
        let userInfo = try ConnectivityCodec.encode(original)
        let decoded = try ConnectivityCodec.decode(userInfo)
        XCTAssertEqual(decoded, original)
        if case let .startWorkout(snap) = decoded {
            XCTAssertEqual(snap.template?.items.count, 1)
            XCTAssertEqual(snap.template?.items.first?.exerciseId, "back-squat")
        } else {
            XCTFail("decoded message not .startWorkout")
        }
    }

    func testStartWorkoutKindIsRoutable() {
        let msg = ConnectivityMessage.startWorkout(
            StartWorkoutSnapshot(templateId: UUID())
        )
        XCTAssertEqual(msg.kind, .startWorkout)
    }

    func testTemplateMessageStillRoundTrips() throws {
        // Sanity: extending ConnectivityMessage with a new case must not
        // break existing case decoding.
        let item = TemplateItemSnapshot(
            id: UUID(),
            index: 0,
            exerciseId: "back-squat",
            targetSets: 4,
            targetReps: 8,
            targetWeightKg: 100,
            targetVelocityMin: 0.5,
            targetVelocityMax: 0.7,
            vlCeiling: 0.20,
            restSeconds: 90,
            sideRaw: "both",
            setSpecs: []
        )
        let template = TemplateSnapshot(
            id: UUID(),
            name: "Strength A",
            scheduledDate: Date(timeIntervalSince1970: 1_700_000_000),
            items: [item]
        )
        let original = ConnectivityMessage.template(template)
        let userInfo = try ConnectivityCodec.encode(original)
        let decoded = try ConnectivityCodec.decode(userInfo)
        XCTAssertEqual(decoded, original)
    }
}
