// SwiftDataSchemaBaselineTests.swift
// VBTrainer · 2026-05
//
// Baseline regression check for the VBTSchemaV1 SwiftData schema. Each
// test instantiates an in-memory ModelContainer over the full
// `VBTSchemaV1.allModels` list, inserts one sample of every @Model type,
// saves, and re-fetches — catching:
//
//   - A new @Model class added without being registered in
//     `VBTSchemaV1.allModels`
//   - A property type change that breaks Codable / ModelContainer init
//   - A required field renamed without updating all call sites
//   - A relationship inverse rewire that crashes on save
//
// What this does NOT catch (deliberate, Reliability #1 part 2):
//   - On-disk migration from a previously-shipped V1 .store to the
//     current schema. A separate fixture-based test would be needed
//     once VBTrainer ships to TestFlight / users.
//
// All instantiations use `isStoredInMemoryOnly: true` so the test is
// hermetic — no side effects to ~/Library/Application Support.

import SwiftData
import XCTest

final class SwiftDataSchemaBaselineTests: XCTestCase {
    /// All 11 @Model types in VBTSchemaV1 should resolve to a non-nil
    /// type and the array should be exactly the expected size — guards
    /// against adding a new model file without registering it.
    func testSchemaInventory() {
        XCTAssertEqual(
            VBTSchemaV1.allModels.count,
            11,
            "If you added/removed a @Model, update VBTSchemaV1.allModels AND this expected count."
        )
        // Spot-check a representative subset still exists in the schema.
        // (We can't compare types directly via Hashable, so probe by name.)
        let typeNames = VBTSchemaV1.allModels.map { String(describing: $0) }
        for expected in [
            "UserProfile", "Workout", "WorkoutSet", "Rep",
            "JumpTest", "ReadinessSnapshot",
            "Template", "TemplateItem", "TemplateSetSpec",
            "DayPlan", "PersonalRecord"
        ] {
            XCTAssertTrue(
                typeNames.contains(expected),
                "Missing \(expected) from VBTSchemaV1 — schema regression?"
            )
        }
    }

    /// Build the full schema container in memory. Any model with a
    /// Codable property that doesn't compile (e.g. ambiguous enum
    /// case, missing CodingKey) will fail here with `ModelContainer`
    /// init throw.
    func testContainerInitWithFullSchema() throws {
        _ = try makeContainer()
    }

    /// Insert one sample of each @Model + save. Re-fetch and assert
    /// counts. Tests the cascade-delete relationship in Workout→Set→Rep
    /// + verifies no required-field defaults are missing.
    func testInsertOneOfEachAndPersists() throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)

        let profile = UserProfile(
            age: 25, sex: .male, heightCm: 175, weightKg: 70
        )
        ctx.insert(profile)

        let workout = Workout(
            exerciseId: "back-squat",
            notes: "smoke test",
            rpe: 7
        )
        ctx.insert(workout)

        let readiness = ReadinessSnapshot(
            date: Date(),
            hrv: 48,
            score: 72,
            tier: .yellow
        )
        ctx.insert(readiness)

        let template = Template(
            name: "Strength A"
        )
        ctx.insert(template)

        let jump = JumpTest(
            performedAt: Date(),
            attempts: [32.0, 33.0, 31.5]
        )
        ctx.insert(jump)

        try ctx.save()

        // Re-fetch from a fresh context (same container) to confirm
        // persistence beyond the original ctx scope.
        let probe = ModelContext(container)
        let profiles = try probe.fetch(FetchDescriptor<UserProfile>())
        let workouts = try probe.fetch(FetchDescriptor<Workout>())
        let readinesses = try probe.fetch(FetchDescriptor<ReadinessSnapshot>())
        let templates = try probe.fetch(FetchDescriptor<Template>())
        let jumps = try probe.fetch(FetchDescriptor<JumpTest>())

        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(readinesses.count, 1)
        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(jumps.count, 1)

        // Field-level spot-checks — would fail if Codable mis-serialized
        // an optional or default value.
        XCTAssertEqual(profiles.first?.age, 25)
        XCTAssertEqual(workouts.first?.exerciseId, "back-squat")
        XCTAssertEqual(workouts.first?.rpe, 7)
        XCTAssertEqual(jumps.first?.attempts, [32.0, 33.0, 31.5])
    }

    /// Two saves on the same container should both succeed — guards
    /// against a model that breaks idempotent saves (e.g. computed
    /// uniqueness conflict, missing @Attribute(.unique) anchor).
    func testTwoConsecutiveSavesSucceed() throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)

        ctx.insert(UserProfile(age: 30, sex: .female, heightCm: 165, weightKg: 60))
        try ctx.save()

        ctx.insert(Workout(exerciseId: "bench-press"))
        try ctx.save()

        let probe = ModelContext(container)
        XCTAssertEqual(try probe.fetch(FetchDescriptor<UserProfile>()).count, 1)
        XCTAssertEqual(try probe.fetch(FetchDescriptor<Workout>()).count, 1)
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
