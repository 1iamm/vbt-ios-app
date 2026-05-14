// RecommendationTemplateBuilder.swift
// VBTrainer · 2026-05
//
// Turns an AIRecommendation into a real Template (with TemplateItem +
// TemplateSetSpec rows) the user can immediately edit / start in PlanView.
// Two builders are provided:
//
//   - buildPRRetest(exerciseId:, lastTopWeight:): 5-set pyramid 50/70/85/95/100%
//     of last top weight, reps decreasing 5/4/3/2/1, rest 2-3 min
//   - buildDeload(baseTemplate:): clones a reference template at 85% weight
//     and -1 rep per set; rest unchanged
//
// Both insert into the @MainActor ModelContext and return the new Template
// for the caller to navigate to.

import Foundation
import SwiftData

@available(iOS 17.0, watchOS 10.0, *)
public enum RecommendationTemplateBuilder {
    /// 5-set pyramid PR re-test for a single exercise.
    @MainActor
    public static func buildPRRetest(
        exerciseId: String,
        lastTopWeight: Double,
        in context: ModelContext
    ) -> Template {
        let exName = ExerciseLookup.exercise(byId: exerciseId)?.nameZH ?? exerciseId
        let template = Template(
            name: "PR 重测 · \(exName)",
            notes: "金字塔加重 · 单动作冲 1RM"
        )
        context.insert(template)

        let item = TemplateItem(
            index: 1,
            exerciseId: exerciseId,
            targetSets: 5,
            targetReps: 1,
            targetWeightKg: lastTopWeight,
            targetVelocityRange: nil,
            vlCeiling: 30,
            restSeconds: 180,
            side: .both
        )
        item.template = template
        template.items.append(item)
        context.insert(item)

        // 2 warm-up + 5 work sets
        let warmups: [(Double, Int, Int)] = [
            (lastTopWeight * 0.40, 8, 90),
            (lastTopWeight * 0.65, 5, 120)
        ]
        let pyramid: [(Double, Int, Int)] = [
            (lastTopWeight * 0.80, 5, 150),
            (lastTopWeight * 0.90, 3, 180),
            (lastTopWeight * 0.95, 2, 180),
            (lastTopWeight * 1.00, 1, 180),
            (lastTopWeight * 1.05, 1, 0) // attempt
        ]
        var idx = 1
        for (w, r, rest) in warmups {
            let s = TemplateSetSpec(
                index: idx,
                kind: .warmUp,
                weightKg: round(w),
                reps: r,
                restSeconds: rest
            )
            s.item = item
            item.setSpecs.append(s)
            context.insert(s)
            idx += 1
        }
        for (w, r, rest) in pyramid {
            let s = TemplateSetSpec(
                index: idx,
                kind: .work,
                weightKg: round(w),
                reps: r,
                restSeconds: rest
            )
            s.item = item
            item.setSpecs.append(s)
            context.insert(s)
            idx += 1
        }
        try? context.save()
        return template
    }

    /// Deload version of an existing template: clone all items, multiply
    /// weights by 0.85, decrease each work set's reps by 1 (clamped ≥ 1).
    @MainActor
    public static func buildDeload(
        baseTemplate: Template,
        in context: ModelContext
    ) -> Template {
        let template = Template(
            name: "减载 · \(baseTemplate.name)",
            notes: "降量 15% · 维持速度 · 神经恢复"
        )
        context.insert(template)

        for orig in baseTemplate.items.sorted(by: { $0.index < $1.index }) {
            let copy = TemplateItem(
                index: orig.index,
                exerciseId: orig.exerciseId,
                targetSets: orig.targetSets,
                targetReps: max(1, orig.targetReps - 1),
                targetWeightKg: orig.targetWeightKg.map { $0 * 0.85 },
                targetVelocityRange: orig.targetVelocityRange,
                vlCeiling: orig.vlCeiling,
                restSeconds: orig.restSeconds,
                side: orig.side
            )
            copy.template = template
            template.items.append(copy)
            context.insert(copy)

            for s in orig.orderedSetSpecs {
                let cs = TemplateSetSpec(
                    index: s.index,
                    kind: s.kind,
                    weightKg: round(s.weightKg * 0.85),
                    reps: s.kind == .work ? max(1, s.reps - 1) : s.reps,
                    restSeconds: s.restSeconds
                )
                cs.item = copy
                copy.setSpecs.append(cs)
                context.insert(cs)
            }
        }
        try? context.save()
        return template
    }
}
