// RecommendationTemplateBuilderTests.swift
// VBTrainer · 2026-05
//
// Task 3 Phase 0 — PR-T3 (part 2). Coverage for the two AI-rec → Template
// builders. These are user-visible: a buggy weight calculation means the
// user starts a session with wrong-weight prescription, which loses trust
// in the recommendation engine.
//
// Coverage matrix:
//   buildPRRetest:
//     - Inserts a Template + exactly 1 TemplateItem + 7 set specs
//     - Set spec ordering: 2 warm-up first (lighter), then 5 pyramid work
//     - Final set is the 1.05× attempt with restSeconds=0
//   buildDeload:
//     - Clones items and set specs from base
//     - All weights are 0.85× original (rounded)
//     - Work-set reps decremented by 1 (clamped to >= 1)
//     - Warm-up rep counts unchanged

import SwiftData
import XCTest

@MainActor
final class RecommendationTemplateBuilderTests: XCTestCase {
    // MARK: - buildPRRetest

    func testBuildPRRetestStructure() throws {
        let ctx = try makeMemoryContext()
        let template = RecommendationTemplateBuilder.buildPRRetest(
            exerciseId: "back-squat",
            lastTopWeight: 100,
            in: ctx
        )

        XCTAssertEqual(template.items.count, 1)
        let item = try XCTUnwrap(template.items.first)
        XCTAssertEqual(item.exerciseId, "back-squat")
        XCTAssertEqual(item.setSpecs.count, 7) // 2 warm-up + 5 work
    }

    func testBuildPRRetestSetOrderAndIntensities() throws {
        let ctx = try makeMemoryContext()
        let template = RecommendationTemplateBuilder.buildPRRetest(
            exerciseId: "back-squat",
            lastTopWeight: 100,
            in: ctx
        )
        let item = try XCTUnwrap(template.items.first)
        let specs = item.orderedSetSpecs
        XCTAssertEqual(specs.map(\.index), [1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(specs[0].kind, .warmUp)
        XCTAssertEqual(specs[1].kind, .warmUp)
        // Pyramid intensities: 80/90/95/100/105 % rounded
        XCTAssertEqual(specs.map(\.weightKg), [40, 65, 80, 90, 95, 100, 105])
        // Final attempt has restSeconds == 0
        XCTAssertEqual(specs.last?.restSeconds, 0)
    }

    // MARK: - buildDeload

    func testBuildDeloadClonesAndDownweights() throws {
        let ctx = try makeMemoryContext()
        let base = Template(name: "Bench Heavy")
        ctx.insert(base)
        let item = TemplateItem(
            index: 1,
            exerciseId: "bench-press",
            targetSets: 5,
            targetReps: 5,
            targetWeightKg: 100
        )
        item.template = base
        base.items.append(item)
        ctx.insert(item)

        let work1 = TemplateSetSpec(index: 1, kind: .work, weightKg: 100, reps: 5, restSeconds: 120)
        work1.item = item
        item.setSpecs.append(work1)
        ctx.insert(work1)
        let warmup = TemplateSetSpec(index: 2, kind: .warmUp, weightKg: 60, reps: 8, restSeconds: 60)
        warmup.item = item
        item.setSpecs.append(warmup)
        try ctx.save()

        let deload = RecommendationTemplateBuilder.buildDeload(baseTemplate: base, in: ctx)
        let cloneItem = try XCTUnwrap(deload.items.first)
        XCTAssertEqual(cloneItem.exerciseId, "bench-press")
        XCTAssertEqual(cloneItem.targetReps, 4, "Item-level reps must decrement by 1")
        XCTAssertEqual(cloneItem.targetWeightKg, 85)

        let specs = cloneItem.orderedSetSpecs
        XCTAssertEqual(specs.count, 2)
        // Work set: 100 × 0.85 = 85, reps 5 → 4
        let workClone = try XCTUnwrap(specs.first { $0.kind == .work })
        XCTAssertEqual(workClone.weightKg, 85)
        XCTAssertEqual(workClone.reps, 4)
        // Warm-up set: 60 × 0.85 = 51, reps 8 stay 8
        let warmupClone = try XCTUnwrap(specs.first { $0.kind == .warmUp })
        XCTAssertEqual(warmupClone.weightKg, 51)
        XCTAssertEqual(warmupClone.reps, 8, "Warm-up rep counts must not be decremented")
    }

    func testBuildDeloadClampsToOneRep() throws {
        let ctx = try makeMemoryContext()
        let base = Template(name: "Singles")
        ctx.insert(base)
        let item = TemplateItem(
            index: 1,
            exerciseId: "deadlift",
            targetSets: 5,
            targetReps: 1 // Already 1 rep
        )
        item.template = base
        base.items.append(item)
        ctx.insert(item)
        let work = TemplateSetSpec(index: 1, kind: .work, weightKg: 200, reps: 1, restSeconds: 180)
        work.item = item
        item.setSpecs.append(work)
        ctx.insert(work)
        try ctx.save()

        let deload = RecommendationTemplateBuilder.buildDeload(baseTemplate: base, in: ctx)
        let cloneItem = try XCTUnwrap(deload.items.first)
        XCTAssertEqual(cloneItem.targetReps, 1, "1-rep prescription must not become 0")
        let clonedWork = try XCTUnwrap(cloneItem.orderedSetSpecs.first)
        XCTAssertEqual(clonedWork.reps, 1, "1-rep work set must stay 1, not 0")
    }

    // MARK: - Helpers

    private func makeMemoryContext() throws -> ModelContext {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
}
