// AIRecommendationEngine.swift
// VBTrainer · 2026-05
//
// V1 doesn't ship real AI. This is a rule-based stub that produces "AI-like"
// template recommendations from local signals (Readiness, days-since-last,
// PR cadence). The shape matches the V4 design's purple AI cards and is the
// integration point V2 will replace with a real model.
//
// Three rules in this version:
//   1. Readiness < 65 → "减载日" — suggest deloading the user's most-trained
//      muscle group at -15% volume
//   2. Last PR attempt > 21 days → "PR 重测" — suggest re-testing the
//      strongest lift
//   3. CMJ baseline established and last CMJ > 7 days → "CMJ 神经测试"
//
// Each rule emits at most one recommendation; we surface up to 2 active rules
// at a time (per design — horizontally scrollable cards).

import Foundation
import SwiftData

public struct AIRecommendation: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let reason: String
    public let meta: String
    public let tags: [String]
    public let kind: Kind
    public let templateIdHint: UUID?
    public let exerciseIdHint: String?
    public let weightHint: Double?

    public enum Kind: String, Sendable {
        case deload
        case prRetest
        case cmjTest
    }

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        reason: String,
        meta: String,
        tags: [String],
        kind: Kind,
        templateIdHint: UUID? = nil,
        exerciseIdHint: String? = nil,
        weightHint: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.reason = reason
        self.meta = meta
        self.tags = tags
        self.kind = kind
        self.templateIdHint = templateIdHint
        self.exerciseIdHint = exerciseIdHint
        self.weightHint = weightHint
    }
}

@available(iOS 17.0, watchOS 10.0, *)
public enum AIRecommendationEngine {
    @MainActor
    public static func recommendations(context: ModelContext) -> [AIRecommendation] {
        var out: [AIRecommendation] = []

        // Rule 1: low readiness → deload (uses most recent template as base)
        if let snap = latestReadiness(context: context),
           let score = snap.score, score < 65
        {
            let baseTemplateId = latestTemplate(context: context)?.id
            out.append(.init(
                title: "减载日",
                subtitle: "基于今日 Readiness \(score)",
                reason: "状态偏低 · 建议降量 −15% 维持速度",
                meta: "降量训练 · 速度向 · ~50min",
                tags: ["减载", "速度向"],
                kind: .deload,
                templateIdHint: baseTemplateId
            ))
        }

        // Rule 2: PR re-test if no recent PR attempt
        if let topExId = topExerciseId(context: context),
           let exName = ExerciseLookup.exercise(byId: topExId)?.nameZH,
           daysSinceLastWorkout(exerciseId: topExId, context: context) >= 21
        {
            let topW = lastTopWeight(exerciseId: topExId, context: context) ?? 100
            out.append(.init(
                title: "\(exName) · PR 重测",
                subtitle: "距离上次 \(daysSinceLastWorkout(exerciseId: topExId, context: context)) 天",
                reason: "建议冲 1RM · 6 组金字塔加重",
                meta: "1 动作 · 6 组 · ~40min",
                tags: ["PR 重测"],
                kind: .prRetest,
                exerciseIdHint: topExId,
                weightHint: topW
            ))
        }

        // Rule 3: CMJ test if not done recently
        if shouldRecommendCMJ(context: context) {
            out.append(.init(
                title: "CMJ 神经测试",
                subtitle: "上次跳跃测试 > 7 天",
                reason: "评估神经系统恢复 · 3 跳取最佳",
                meta: "3 attempts · ~5min",
                tags: ["CMJ", "神经"],
                kind: .cmjTest
            ))
        }

        return Array(out.prefix(2))
    }

    // MARK: - Helpers

    @MainActor
    private static func latestReadiness(context: ModelContext) -> ReadinessSnapshot? {
        var fd = FetchDescriptor<ReadinessSnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        fd.fetchLimit = 1
        return (try? context.fetch(fd))?.first
    }

    @MainActor
    private static func topExerciseId(context: ModelContext) -> String? {
        var fd = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        fd.fetchLimit = 90
        let workouts = (try? context.fetch(fd)) ?? []
        let counts = Dictionary(grouping: workouts, by: \.exerciseId).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    @MainActor
    private static func daysSinceLastWorkout(exerciseId: String, context: ModelContext) -> Int {
        var fd = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        fd.fetchLimit = 1
        guard let last = (try? context.fetch(fd))?.first else { return 999 }
        return max(0, Calendar.current.dateComponents([.day], from: last.startedAt, to: Date()).day ?? 0)
    }

    @MainActor
    private static func latestTemplate(context: ModelContext) -> Template? {
        var fd = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        fd.fetchLimit = 1
        return (try? context.fetch(fd))?.first
    }

    @MainActor
    private static func lastTopWeight(exerciseId: String, context: ModelContext) -> Double? {
        var fd = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        fd.fetchLimit = 1
        guard let last = (try? context.fetch(fd))?.first else { return nil }
        return last.sets.map(\.weightKg).max()
    }

    @MainActor
    private static func shouldRecommendCMJ(context: ModelContext) -> Bool {
        var fd = FetchDescriptor<JumpTest>(
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        fd.fetchLimit = 1
        guard let last = (try? context.fetch(fd))?.first else { return true }
        let days = Calendar.current.dateComponents([.day], from: last.performedAt, to: Date()).day ?? 0
        return days >= 7
    }
}
