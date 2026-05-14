// GoalTheme.swift
// VBTrainer · 2026-05
//
// Maps the user's TrainingGoal to an accent color (and friendly Chinese label).
// Drives the ad-hoc theming the V4 design specified: switching goal recolors
// the primary accent across cards, chips, and CTAs.

import SwiftUI

public enum GoalTheme {
    public static func accent(for goal: TrainingGoal) -> Color {
        switch goal {
        case .power: Color(hex: "FF3B30") // 爆发 — 系统红
        case .strength: Tokens.Color.accent // 力量 — 品牌橙
        case .muscle: Color(hex: "BF5AF2") // 增肌 — 紫
        case .fatLoss: Color(hex: "32ADE6") // 减脂 — 浅蓝
        case .general: Color(hex: "5E5CE6") // 综合 — 靛
        }
    }

    public static func label(for goal: TrainingGoal) -> String {
        switch goal {
        case .power: "爆发"
        case .strength: "力量"
        case .muscle: "增肌"
        case .fatLoss: "减脂"
        case .general: "综合"
        }
    }

    /// Default VL ceiling per goal (PRD §M5).
    public static func defaultVLCeiling(for goal: TrainingGoal) -> Double {
        switch goal {
        case .power: 10
        case .strength: 20
        case .muscle: 30
        case .fatLoss: 40
        case .general: 25
        }
    }
}
