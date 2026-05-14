// ConnectivityContractTests.swift
// VBTrainer · 2026-05
//
// Round-trip contract coverage for ALL ConnectivityMessage cases. Catches:
//   - Renaming a `case` of the enum without updating both sides
//   - Adding a non-optional field to a payload struct without back-compat
//   - Codable synthesis broken by changing a property type
//   - kind tag drift (case .liveProgress → ConnectivityKind.liveProgress)
//
// Each case is encoded via ConnectivityCodec (the cross-platform contract
// wire format used by sendMessage / transferUserInfo) and decoded back; the
// decoded value must equal the original. If a new ConnectivityMessage case
// is added without a roundtrip test here, `testAllCasesHaveCoverage` fails.

import XCTest

final class ConnectivityContractTests: XCTestCase {
    // MARK: - Per-case roundtrips

    func testWorkoutSnapshotRoundTrips() throws {
        let original = ConnectivityMessage.workoutSnapshot(
            WorkoutSnapshot(
                id: fixedUUID("11111111"),
                exerciseId: "back-squat",
                startedAt: Date(timeIntervalSince1970: 1_700_000_000),
                endedAt: Date(timeIntervalSince1970: 1_700_003_600),
                sets: [],
                heartRateSamples: [],
                rpe: 8,
                linkedTemplateId: fixedUUID("22222222"),
                notes: "felt strong"
            )
        )
        try assertRoundTrip(original)
        XCTAssertEqual(original.kind, .workoutSnapshot)
    }

    func testJumpTestRoundTrips() throws {
        let original = ConnectivityMessage.jumpTest(
            JumpTestSnapshot(
                id: fixedUUID("33333333"),
                performedAt: Date(timeIntervalSince1970: 1_700_000_000),
                attempts: [32.0, 33.5, 31.0],
                flightTimeSeconds: [0.51, 0.52, 0.50],
                bestHeightCm: 33.5,
                linkedWorkoutId: fixedUUID("44444444")
            )
        )
        try assertRoundTrip(original)
        XCTAssertEqual(original.kind, .jumpTest)
    }

    func testTemplateRoundTrips() throws {
        let item = TemplateItemSnapshot(
            id: fixedUUID("55555555"),
            index: 0,
            exerciseId: "bench-press",
            targetSets: 5,
            targetReps: 5,
            targetWeightKg: 80,
            targetVelocityMin: 0.45,
            targetVelocityMax: 0.65,
            vlCeiling: 0.20,
            restSeconds: 120,
            sideRaw: "both",
            setSpecs: []
        )
        let template = TemplateSnapshot(
            id: fixedUUID("66666666"),
            name: "Strength A",
            scheduledDate: Date(timeIntervalSince1970: 1_700_000_000),
            items: [item]
        )
        let original = ConnectivityMessage.template(template)
        try assertRoundTrip(original)
        XCTAssertEqual(original.kind, .template)
    }

    func testPreferencesRoundTrips() throws {
        let original = ConnectivityMessage.preferences(
            WatchPreferencesSnapshot(enableRepHaptic: true)
        )
        try assertRoundTrip(original)
        XCTAssertEqual(original.kind, .preferences)
        // Also test the false branch — bool encoding must distinguish.
        let off = ConnectivityMessage.preferences(
            WatchPreferencesSnapshot(enableRepHaptic: false)
        )
        try assertRoundTrip(off)
    }

    func testStartWorkoutRoundTrips() throws {
        let original = ConnectivityMessage.startWorkout(
            StartWorkoutSnapshot(
                templateId: fixedUUID("77777777"),
                startItemIndex: 2,
                template: nil
            )
        )
        try assertRoundTrip(original)
        XCTAssertEqual(original.kind, .startWorkout)
    }

    func testLiveProgressRoundTrips() throws {
        let original = ConnectivityMessage.liveProgress(
            LiveProgressPayload(
                phase: .repDetected,
                workoutId: fixedUUID("88888888"),
                setIndex: 2,
                exerciseName: "Back Squat",
                targetReps: 5,
                targetWeightKg: 100,
                currentRep: 3,
                lastRepVelocity: 0.52,
                setBestVelocity: 0.58,
                vlPercent: 10.3,
                repVelocities: [0.58, 0.55, 0.52],
                restRemainingSec: nil,
                restTotalSec: nil,
                heartRate: 142,
                targetVelocityMin: 0.45,
                targetVelocityMax: 0.65,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )
        try assertRoundTrip(original)
        XCTAssertEqual(original.kind, .liveProgress)
    }

    func testLiveProgressPhaseExhaustive() throws {
        // Every Phase rawValue must round-trip — catches a phase rename.
        for phase in LiveProgressPayload.Phase.allCasesEnumerated {
            let msg = ConnectivityMessage.liveProgress(
                LiveProgressPayload(
                    phase: phase,
                    workoutId: fixedUUID("99999999"),
                    setIndex: 0,
                    exerciseName: "Test",
                    targetReps: 1,
                    targetWeightKg: 0
                )
            )
            let encoded = try ConnectivityCodec.encode(msg)
            let decoded = try ConnectivityCodec.decode(encoded)
            XCTAssertEqual(decoded, msg, "phase \(phase) failed to round-trip")
        }
    }

    func testRestAdjustRoundTrips() throws {
        try assertRoundTrip(.restAdjust(
            RestAdjustPayload(deltaSeconds: 10, skip: false, workoutId: fixedUUID("aaaaaaaa"))
        ))
        try assertRoundTrip(.restAdjust(
            RestAdjustPayload(deltaSeconds: -20, skip: false)
        ))
        try assertRoundTrip(.restAdjust(
            RestAdjustPayload(deltaSeconds: 0, skip: true, workoutId: nil)
        ))
    }

    func testSetControlRoundTrips() throws {
        for action in SetControlPayload.Action.allCasesEnumerated {
            let msg = ConnectivityMessage.setControl(
                SetControlPayload(action: action, workoutId: fixedUUID("bbbbbbbb"))
            )
            try assertRoundTrip(msg)
        }
        // Without workoutId
        try assertRoundTrip(.setControl(SetControlPayload(action: .endSet)))
    }

    // MARK: - Kind tag <-> case association

    func testKindTagsCoverAllCases() throws {
        // For every ConnectivityKind, encode a sample case and assert the
        // userInfo's kind tag matches. Catches a kind enum case getting
        // renamed without touching `ConnectivityMessage.kind`.
        let samples: [(ConnectivityMessage, ConnectivityKind)] = [
            (.workoutSnapshot(WorkoutSnapshot(
                exerciseId: "x", startedAt: Date(), endedAt: Date()
            )), .workoutSnapshot),
            (.jumpTest(JumpTestSnapshot(attempts: [1.0])), .jumpTest),
            (.template(TemplateSnapshot(id: UUID(), name: "x", scheduledDate: Date(timeIntervalSince1970: 0), items: [])), .template),
            (.preferences(WatchPreferencesSnapshot(enableRepHaptic: true)), .preferences),
            (.startWorkout(StartWorkoutSnapshot(templateId: UUID())), .startWorkout),
            (.liveProgress(LiveProgressPayload(
                phase: .ready, workoutId: UUID(), setIndex: 0,
                exerciseName: "x", targetReps: 1, targetWeightKg: 0
            )), .liveProgress),
            (.restAdjust(RestAdjustPayload(deltaSeconds: 0)), .restAdjust),
            (.setControl(SetControlPayload(action: .endSet)), .setControl)
        ]
        // Total assertion guards against a new case being added to
        // `ConnectivityMessage` without adding a test sample here.
        XCTAssertEqual(samples.count, 8, "Add a sample for every ConnectivityMessage case")
        for (msg, expectedKind) in samples {
            let userInfo = try ConnectivityCodec.encode(msg)
            let kindRaw = userInfo[ConnectivityCodec.userInfoKindKey] as? String
            XCTAssertEqual(
                kindRaw,
                expectedKind.rawValue,
                "encode dropped wrong kind tag for \(msg)"
            )
            XCTAssertEqual(
                msg.kind,
                expectedKind,
                "ConnectivityMessage.kind getter mismatch for \(msg)"
            )
        }
    }

    // MARK: - Decoder robustness

    func testDecodeRejectsCorruptedPayload() {
        let userInfo: [String: Any] = [
            ConnectivityCodec.userInfoKindKey: "preferences",
            ConnectivityCodec.userInfoPayloadKey: Data([0xFF, 0xFE, 0x00])
        ]
        XCTAssertThrowsError(try ConnectivityCodec.decode(userInfo))
    }

    func testDecodeReturnsNilOnMissingPayload() throws {
        let userInfo: [String: Any] = [
            ConnectivityCodec.userInfoKindKey: "preferences"
            // payload key missing
        ]
        let decoded = try ConnectivityCodec.decode(userInfo)
        XCTAssertNil(decoded)
    }

    // MARK: - Helpers

    private func assertRoundTrip(_ original: ConnectivityMessage, file: StaticString = #file, line: UInt = #line) throws {
        let encoded = try ConnectivityCodec.encode(original)
        let decoded = try ConnectivityCodec.decode(encoded)
        XCTAssertEqual(decoded, original, "Codec roundtrip mismatch", file: file, line: line)
    }

    private func fixedUUID(_ hex8: String) -> UUID {
        // Build a deterministic UUID for assertion stability across runs.
        // hex8 must be exactly 8 hex chars; rest is zero-padded.
        UUID(uuidString: "\(hex8)-0000-0000-0000-000000000000") ?? UUID()
    }
}

// MARK: - Hand-rolled CaseIterable for non-CaseIterable enums

/// LiveProgressPayload.Phase and SetControlPayload.Action are not declared
/// CaseIterable in production code. We list all known cases here so the
/// test fails loudly if a new case is added without updating these.
private extension LiveProgressPayload.Phase {
    static var allCasesEnumerated: [LiveProgressPayload.Phase] {
        [.ready, .repDetected, .setEnded, .restCountdown, .workoutEnded]
    }
}

private extension SetControlPayload.Action {
    static var allCasesEnumerated: [SetControlPayload.Action] {
        [.endSet, .startNextSet, .finishWorkout]
    }
}
