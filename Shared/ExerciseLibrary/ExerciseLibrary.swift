// ExerciseLibrary.swift
// VBTrainer · 2026-05
//
// 30 exercises supported in V1. V1RM defaults and VL ceilings are
// derived from the cited literature (see Citations.swift).
//
// Citation convention (REQUIRED): each `referenceV1RM` value is preceded
// by a doc comment naming the citation symbol so the link survives grep.
//
// SF Symbol notes: many lifts share the same generic symbol since SF
// Symbols 4 doesn't ship dedicated icons for every variant. This is fine
// for V1; design will refine in a later pass.

import Foundation

public let exerciseLibrary: [Exercise] = [

    // MARK: - Barbell (16)

    // Reference: Citations.gonzalezBadillo2010Velocity (squat MV ≈ 0.30 m/s @ 1RM)
    Exercise(
        id: "back-squat",
        nameZH: "深蹲",
        nameEN: "Back Squat",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.30,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.45...0.65,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [
            Citations.gonzalezBadillo2010Velocity.id,
            Citations.sanchezMedina2011VL.id,
        ]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (front squat slightly faster than back)
    Exercise(
        id: "front-squat",
        nameZH: "前蹲",
        nameEN: "Front Squat",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.32,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.50...0.70,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (high-bar variant; treat similar to back squat)
    Exercise(
        id: "high-bar-squat",
        nameZH: "高杠深蹲",
        nameEN: "High-Bar Squat",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.30,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.45...0.65,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (low-bar slightly slower at 1RM)
    Exercise(
        id: "low-bar-squat",
        nameZH: "低杠深蹲",
        nameEN: "Low-Bar Squat",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.28,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.42...0.60,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (bench MPV ≈ 0.17 m/s @ 1RM)
    // Reference: Citations.sanchezMedina2010Propulsive (bench has a strong braking phase → use MPV)
    Exercise(
        id: "bench-press",
        nameZH: "卧推",
        nameEN: "Bench Press",
        category: .barbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.17,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [
            Citations.gonzalezBadillo2010Velocity.id,
            Citations.sanchezMedina2010Propulsive.id,
            Citations.sanchezMedina2011VL.id,
            Citations.balshaw2023AppleWatch.id,
        ]
    ),

    // Reference: Citations.garciaRamos2018LVPVariants (incline slightly slower)
    Exercise(
        id: "incline-bench-press",
        nameZH: "上斜卧推",
        nameEN: "Incline Bench Press",
        category: .barbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.18,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.garciaRamos2018LVPVariants.id]
    ),

    // Reference: Citations.garciaRamos2018LVPVariants (decline reference value)
    Exercise(
        id: "decline-bench-press",
        nameZH: "下斜卧推",
        nameEN: "Decline Bench Press",
        category: .barbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.17,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.garciaRamos2018LVPVariants.id]
    ),

    // Reference: Citations.garciaRamos2018LVPVariants (close-grip slightly faster at 1RM)
    Exercise(
        id: "close-grip-bench-press",
        nameZH: "窄距卧推",
        nameEN: "Close-Grip Bench Press",
        category: .barbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.20,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.garciaRamos2018LVPVariants.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (deadlift MV ≈ 0.15 m/s @ 1RM)
    Exercise(
        id: "deadlift",
        nameZH: "硬拉",
        nameEN: "Conventional Deadlift",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.15,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.30...0.50,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (sumo similar to conventional)
    Exercise(
        id: "sumo-deadlift",
        nameZH: "相扑硬拉",
        nameEN: "Sumo Deadlift",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.15,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.30...0.50,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (RDL is partial-ROM; use deadlift-like band)
    Exercise(
        id: "romanian-deadlift",
        nameZH: "罗马尼亚硬拉",
        nameEN: "Romanian Deadlift",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.20,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.35...0.55,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.sanchezMedina2010Propulsive (overhead has braking → MPV)
    Exercise(
        id: "standing-overhead-press",
        nameZH: "站姿肩推",
        nameEN: "Standing Overhead Press",
        category: .barbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.18,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.sanchezMedina2010Propulsive.id]
    ),

    // Reference: Citations.sanchezMedina2010Propulsive (seated similar to standing OHP)
    Exercise(
        id: "seated-overhead-press",
        nameZH: "坐姿肩推",
        nameEN: "Seated Overhead Press",
        category: .barbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.18,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.sanchezMedina2010Propulsive.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (push-press is explosive → use PV)
    Exercise(
        id: "push-press",
        nameZH: "借力推",
        nameEN: "Push Press",
        category: .barbell,
        defaultVelocityVariant: .pv,
        referenceV1RM: 0.50,
        defaultVLCeiling: 15,
        defaultTargetVelocityRange: 0.80...1.20,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id],
        notes: "Explosive variant — peak velocity is the primary metric."
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (rows: limited literature, use conservative MV)
    Exercise(
        id: "barbell-row",
        nameZH: "杠铃划船",
        nameEN: "Barbell Row",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.30,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.50...0.75,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.gonzalezBadillo2010Velocity (curl is small-muscle; use looser thresholds)
    Exercise(
        id: "barbell-curl",
        nameZH: "杠铃弯举",
        nameEN: "Barbell Curl",
        category: .barbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.35,
        defaultVLCeiling: 30,
        defaultTargetVelocityRange: 0.50...0.80,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // MARK: - Dumbbell (6)

    // Reference: Citations.sanchezMedina2010Propulsive (DB press has braking → MPV)
    Exercise(
        id: "dumbbell-press",
        nameZH: "哑铃推举",
        nameEN: "Dumbbell Bench Press",
        category: .dumbbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.18,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "dumbbell.fill",
        citationIds: [Citations.sanchezMedina2010Propulsive.id]
    ),

    Exercise(
        id: "dumbbell-fly",
        nameZH: "哑铃飞鸟",
        nameEN: "Dumbbell Fly",
        category: .dumbbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: nil,                  // single-joint isolation; LVP not commonly profiled
        defaultVLCeiling: 30,
        defaultTargetVelocityRange: 0.40...0.70,
        sfSymbol: "dumbbell.fill",
        citationIds: [Citations.sanchezMedina2011VL.id]
    ),

    Exercise(
        id: "dumbbell-row",
        nameZH: "哑铃划船",
        nameEN: "Dumbbell Row",
        category: .dumbbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.30,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.50...0.75,
        isUnilateral: true,
        sfSymbol: "dumbbell.fill",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    Exercise(
        id: "dumbbell-curl",
        nameZH: "哑铃弯举",
        nameEN: "Dumbbell Curl",
        category: .dumbbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.35,
        defaultVLCeiling: 30,
        defaultTargetVelocityRange: 0.50...0.80,
        sfSymbol: "dumbbell.fill",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    Exercise(
        id: "dumbbell-shoulder-press",
        nameZH: "哑铃肩推",
        nameEN: "Dumbbell Shoulder Press",
        category: .dumbbell,
        defaultVelocityVariant: .mpv,
        referenceV1RM: 0.18,
        defaultVLCeiling: 20,
        defaultTargetVelocityRange: 0.40...0.55,
        sfSymbol: "dumbbell.fill",
        citationIds: [Citations.sanchezMedina2010Propulsive.id]
    ),

    Exercise(
        id: "bulgarian-split-squat",
        nameZH: "保加利亚分腿蹲",
        nameEN: "Bulgarian Split Squat",
        category: .dumbbell,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.35,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.50...0.75,
        isUnilateral: true,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // MARK: - Bodyweight / Machine (8)

    Exercise(
        id: "pull-up",
        nameZH: "引体向上",
        nameEN: "Pull-Up",
        category: .bodyweight,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.23,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.40...0.70,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id],
        notes: "Add weight via belt to use VBT thresholds; bodyweight reps cluster by RPE."
    ),

    Exercise(
        id: "push-up",
        nameZH: "俯卧撑",
        nameEN: "Push-Up",
        category: .bodyweight,
        defaultVelocityVariant: .mv,
        referenceV1RM: nil,
        defaultVLCeiling: 35,
        defaultTargetVelocityRange: 0.50...1.20,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.sanchezMedina2011VL.id]
    ),

    Exercise(
        id: "air-squat",
        nameZH: "自重深蹲",
        nameEN: "Air Squat",
        category: .bodyweight,
        defaultVelocityVariant: .mv,
        referenceV1RM: nil,
        defaultVLCeiling: 35,
        defaultTargetVelocityRange: 0.70...1.40,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.sanchezMedina2011VL.id]
    ),

    Exercise(
        id: "dip",
        nameZH: "双杠臂屈伸",
        nameEN: "Dip",
        category: .bodyweight,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.25,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.40...0.70,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    Exercise(
        id: "lat-pulldown",
        nameZH: "高位下拉",
        nameEN: "Lat Pulldown",
        category: .machine,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.30,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.50...0.75,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    Exercise(
        id: "seated-row",
        nameZH: "坐姿划船",
        nameEN: "Seated Cable Row",
        category: .machine,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.30,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.50...0.75,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    Exercise(
        id: "leg-press",
        nameZH: "腿举",
        nameEN: "Leg Press",
        category: .machine,
        defaultVelocityVariant: .mv,
        referenceV1RM: 0.40,
        defaultVLCeiling: 25,
        defaultTargetVelocityRange: 0.55...0.85,
        sfSymbol: "figure.strengthtraining.traditional",
        citationIds: [Citations.gonzalezBadillo2010Velocity.id]
    ),

    // Reference: Citations.claudino2017CMJ — neuromuscular monitoring via CMJ
    // Reference: Citations.linthorne2001Jump — flight-time method (h = g·t²/8)
    Exercise(
        id: "cmj",
        nameZH: "CMJ 跳跃",
        nameEN: "Counter-Movement Jump",
        category: .jump,
        defaultVelocityVariant: .pv,
        referenceV1RM: nil,                   // jump height is the metric, not load
        defaultVLCeiling: 15,
        defaultTargetVelocityRange: 2.0...4.0, // peak takeoff velocity (m/s)
        sfSymbol: "figure.run",
        citationIds: [
            Citations.claudino2017CMJ.id,
            Citations.watkins2017CMJReadiness.id,
            Citations.linthorne2001Jump.id,
        ],
        notes: "Used both as an exercise and (more commonly) as a daily neuromuscular state test."
    ),
]
