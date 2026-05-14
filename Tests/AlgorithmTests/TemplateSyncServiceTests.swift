// TemplateSyncServiceTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0 — PR-T3 (part 1). Coverage for the
// `Template → TemplateSnapshot` codec used by iPhone→Watch sync. A
// regression here means the Watch silently receives a *different* plan
// than the iPhone shows — possibly with sets reordered or weights
// dropped — and the user spends a session under the wrong prescription.
//
// `push()` itself wraps WCSession and is platform-gated; only the
// pure `snapshot(of:on:)` transform is testable in unit context.
//
// Coverage matrix:
//   - Top-level Template.id / .name preserved
//   - scheduledDate normalised to startOfDay (regardless of input time)
//   - items emitted sorted by index even when stored out of order
//   - per-item fields (targetSets/targetReps/weight/velocity/vlCeiling/rest/side)
//   - per-set specs preserved & ordered
//   - empty template → empty items array (no crash)

import SwiftData
import XCTest

@MainActor
final class TemplateSyncServiceTests: XCTestCase {
    func testSnapshotPreservesTopLevelFields() throws {
        let ctx = try makeMemoryContext()
        let id = UUID()
        let t = Template(id: id, name: "Push Day A", notes: "test")
        ctx.insert(t)
        try ctx.save()

        let snap = TemplateSyncService.snapshot(of: t, on: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(snap.id, id)
        XCTAssertEqual(snap.name, "Push Day A")
        XCTAssertEqual(snap.items.count, 0)
    }

    func testSnapshotNormalisesDateToStartOfDay() throws {
        let ctx = try makeMemoryContext()
        let t = Template(name: "x")
        ctx.insert(t)
        try ctx.save()

        // Pick a date that is provably not start-of-day in current timezone.
        let mid = Date(timeIntervalSince1970: 1_700_045_321)
        let snap = TemplateSyncService.snapshot(of: t, on: mid)
        let expected = Calendar.current.startOfDay(for: mid)
        XCTAssertEqual(snap.scheduledDate, expected)
    }

    func testSnapshotSortsItemsByIndex() throws {
        let ctx = try makeMemoryContext()
        let t = Template(name: "Mixed-order")
        ctx.insert(t)
        // Insert items in reverse index order; snapshot must restore ascending.
        for i in (1...3).reversed() {
            let item = TemplateItem(
                index: i,
                exerciseId: "ex-\(i)",
                targetSets: 3,
                targetReps: 5
            )
            item.template = t
            t.items.append(item)
            ctx.insert(item)
        }
        try ctx.save()

        let snap = TemplateSyncService.snapshot(of: t, on: Date())
        XCTAssertEqual(snap.items.map(\.index), [1, 2, 3])
        XCTAssertEqual(snap.items.map(\.exerciseId), ["ex-1", "ex-2", "ex-3"])
    }

    func testSnapshotPreservesItemFields() throws {
        let ctx = try makeMemoryContext()
        let t = Template(name: "Bench Heavy")
        ctx.insert(t)
        let item = TemplateItem(
            index: 1,
            exerciseId: "bench-press",
            targetSets: 5,
            targetReps: 3,
            targetWeightKg: 100,
            targetVelocityRange: 0.45...0.65,
            vlCeiling: 20,
            restSeconds: 150,
            side: .both
        )
        item.template = t
        t.items.append(item)
        ctx.insert(item)
        try ctx.save()

        let snap = TemplateSyncService.snapshot(of: t, on: Date())
        let s = try XCTUnwrap(snap.items.first)
        XCTAssertEqual(s.exerciseId, "bench-press")
        XCTAssertEqual(s.targetSets, 5)
        XCTAssertEqual(s.targetReps, 3)
        XCTAssertEqual(s.targetWeightKg, 100)
        XCTAssertEqual(s.targetVelocityMin, 0.45)
        XCTAssertEqual(s.targetVelocityMax, 0.65)
        XCTAssertEqual(s.vlCeiling, 20)
        XCTAssertEqual(s.restSeconds, 150)
        XCTAssertEqual(s.sideRaw, Side.both.rawValue)
    }

    func testSnapshotPreservesPerSetSpecsInOrder() throws {
        let ctx = try makeMemoryContext()
        let t = Template(name: "Squat 5x5")
        ctx.insert(t)
        let item = TemplateItem(index: 1, exerciseId: "back-squat")
        item.template = t
        t.items.append(item)
        ctx.insert(item)

        // Out-of-order insertion to verify ordering is by `index`, not insertion.
        for i in [3, 1, 5, 2, 4] {
            let s = TemplateSetSpec(
                index: i,
                kind: i == 1 ? .warmUp : .work,
                weightKg: 50.0 + Double(i) * 10.0,
                reps: 5,
                restSeconds: 120
            )
            s.item = item
            item.setSpecs.append(s)
            ctx.insert(s)
        }
        try ctx.save()

        let snap = TemplateSyncService.snapshot(of: t, on: Date())
        let specs = snap.items.first?.setSpecs ?? []
        XCTAssertEqual(specs.map(\.index), [1, 2, 3, 4, 5])
        XCTAssertEqual(specs.map(\.weightKg), [60, 70, 80, 90, 100])
        XCTAssertEqual(specs.first?.kindRaw, TemplateSetKind.warmUp.rawValue)
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
