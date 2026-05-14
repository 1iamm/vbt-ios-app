// JSONImporterTests.swift
// VBTrainer · 2026-05
//
// Round-trip coverage for VBTBackup ↔ JSONImporter. Exporter writes a
// JSON blob, Importer reads it back, content must match. Also verifies
// idempotent re-import (no duplicates).

import SwiftData
import XCTest

final class JSONImporterTests: XCTestCase {
    func testRoundTripEmptyBackup() throws {
        let backup = VBTBackup(
            workouts: [],
            jumpTests: [],
            readinessSnapshots: [],
            personalRecords: []
        )
        let data = try JSONEncoder().encode(backup)
        let ctx = try makeMemoryContext()
        let result = try JSONImporter.restore(from: data, in: ctx)
        XCTAssertEqual(result.workoutsInserted, 0)
        XCTAssertEqual(result.jumpTestsInserted, 0)
        XCTAssertEqual(result.readinessInserted, 0)
        XCTAssertEqual(result.personalRecordsInserted, 0)
    }

    func testImportInsertsWorkoutsAndIsIdempotent() throws {
        let snap = WorkoutSnapshot(
            id: UUID(),
            exerciseId: "back-squat",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_003_600),
            sets: [],
            heartRateSamples: [],
            rpe: 7
        )
        let backup = VBTBackup(
            workouts: [snap],
            jumpTests: [],
            readinessSnapshots: [],
            personalRecords: []
        )
        let data = try JSONEncoder().encode(backup)
        let ctx = try makeMemoryContext()

        // First import: insert
        let first = try JSONImporter.restore(from: data, in: ctx)
        XCTAssertEqual(first.workoutsInserted, 1)
        XCTAssertEqual(first.workoutsSkipped, 0)

        // Second import: skip (id match)
        let second = try JSONImporter.restore(from: data, in: ctx)
        XCTAssertEqual(second.workoutsInserted, 0)
        XCTAssertEqual(second.workoutsSkipped, 1)

        // Final state has exactly one Workout
        let probe = try ctx.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(probe.count, 1)
        XCTAssertEqual(probe.first?.exerciseId, "back-squat")
    }

    func testImportInsertsJumpTestsReadinessAndPRs() throws {
        let backup = VBTBackup(
            workouts: [],
            jumpTests: [
                JumpTestSnapshot(
                    id: UUID(),
                    performedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    attempts: [33.0, 35.5, 34.0],
                    flightTimeSeconds: [0.52, 0.54, 0.53],
                    bestHeightCm: 35.5,
                    linkedWorkoutId: nil
                )
            ],
            readinessSnapshots: [
                ReadinessSnapshotDTO(
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    score: 78,
                    tier: "yellow",
                    hrv: 48,
                    restingHR: 56,
                    sleepDurationHours: 7.3,
                    deepSleepHours: 1.2,
                    wristTemperatureDelta: 0.1
                )
            ],
            personalRecords: [
                PRDTO(
                    exerciseId: "back-squat",
                    kind: "maxWeight",
                    value: 145,
                    achievedAt: Date(timeIntervalSince1970: 1_700_000_000)
                )
            ]
        )
        let data = try JSONEncoder().encode(backup)
        let ctx = try makeMemoryContext()
        let result = try JSONImporter.restore(from: data, in: ctx)

        XCTAssertEqual(result.jumpTestsInserted, 1)
        XCTAssertEqual(result.readinessInserted, 1)
        XCTAssertEqual(result.personalRecordsInserted, 1)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<JumpTest>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ReadinessSnapshot>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<PersonalRecord>()).count, 1)
    }

    /// Round 3 Reliability P2 carry-over: idempotency was previously only
    /// proven for Workouts. JumpTest / ReadinessSnapshot / PersonalRecord
    /// share the same id-based skip pattern, but a regression in any of
    /// them would silently duplicate user data on re-import.
    func testReImportingAllKindsIsIdempotent() throws {
        let jumpId = UUID()
        let backup = VBTBackup(
            workouts: [],
            jumpTests: [
                JumpTestSnapshot(
                    id: jumpId,
                    performedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    attempts: [30.0, 31.0, 32.0],
                    flightTimeSeconds: [0.50, 0.52, 0.54],
                    bestHeightCm: 32.0,
                    linkedWorkoutId: nil
                ),
            ],
            readinessSnapshots: [
                ReadinessSnapshotDTO(
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    score: 80,
                    tier: "green",
                    hrv: 55,
                    restingHR: 54,
                    sleepDurationHours: 8.0,
                    deepSleepHours: 1.4,
                    wristTemperatureDelta: 0.0
                ),
            ],
            personalRecords: [
                PRDTO(
                    exerciseId: "bench-press",
                    kind: "maxWeight",
                    value: 100,
                    achievedAt: Date(timeIntervalSince1970: 1_700_000_000)
                ),
            ]
        )
        let data = try JSONEncoder().encode(backup)
        let ctx = try makeMemoryContext()

        // First import — inserts all three.
        let first = try JSONImporter.restore(from: data, in: ctx)
        XCTAssertEqual(first.jumpTestsInserted, 1)
        XCTAssertEqual(first.readinessInserted, 1)
        XCTAssertEqual(first.personalRecordsInserted, 1)

        // Second import — all four kinds now idempotent.
        //   - JumpTest dedupes by id
        //   - Readiness dedupes by date
        //   - PR dedupes by (exerciseId, kind, value, achievedAt) tuple
        //     (Round 3 Reliability C2 — fixed)
        //   - Workout dedupes by id (covered in testImportInsertsWorkoutsAndIsIdempotent)
        let second = try JSONImporter.restore(from: data, in: ctx)
        XCTAssertEqual(second.jumpTestsInserted, 0, "JumpTest re-import must dedupe by id")
        XCTAssertEqual(second.readinessInserted, 0, "Readiness re-import must dedupe by date")
        XCTAssertEqual(
            second.personalRecordsInserted, 0,
            "PR re-import dedupes by (exerciseId, kind, value, achievedAt) tuple"
        )

        // Final-state counts: one of each kind. Re-importing identical
        // backups must not multiply rows.
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<JumpTest>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ReadinessSnapshot>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<PersonalRecord>()).count, 1)
    }

    func testMalformedJSONThrows() {
        let ctx = try? makeMemoryContext()
        guard let ctx else { XCTFail("ctx setup failed"); return }
        XCTAssertThrowsError(try JSONImporter.restore(from: Data([0xFF, 0xFE]), in: ctx)) { err in
            if case JSONImporter.ImportError.malformedJSON = err { return }
            XCTFail("Expected .malformedJSON, got \(err)")
        }
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
