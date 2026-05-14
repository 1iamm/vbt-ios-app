// Tokens.swift
// VBTrainer · 2026-05
//
// Single source of truth for design tokens. Mirrors the values in
// design/iphone/vbt-iphone/project/vbt-tokens.jsx, which the user
// approved in Claude Design (Tweaks: 数据密度=标准 / Readiness=圆环).
//
// Usage:
//     .padding(Tokens.Space.lg)
//     .foregroundStyle(Tokens.Color.accent)
//     .font(Tokens.Font.numericLarge)
//
// Light/Dark adaptation:
//   - Neutral colors (label/secondary/bg/...) come from SwiftUI semantic
//     colors and adapt automatically.
//   - Accent + data colors are fixed hex (designed to read in both modes).

import SwiftUI

public enum Tokens {
    // MARK: - Color

    public enum Color {
        // Neutrals — cross-platform (iOS + watchOS) semantic colors.
        // SwiftUI's `.primary` and `.secondary` adapt automatically to
        // light/dark. For the iOS-only grouped/card backgrounds we use
        // platform-specific colors guarded by #if.
        public static let label = SwiftUI.Color.primary
        public static let secondaryLabel = SwiftUI.Color.secondary
        public static let tertiaryLabel = SwiftUI.Color.secondary.opacity(0.6)
        public static let separator = SwiftUI.Color.gray.opacity(0.3)

        #if os(iOS)
            public static let bg = SwiftUI.Color(.systemBackground)
            public static let groupedBg = SwiftUI.Color(.systemGroupedBackground)
            public static let card = SwiftUI.Color(.secondarySystemGroupedBackground)
            public static let fill = SwiftUI.Color(.tertiarySystemFill)
        #else
            // watchOS uses pure black backgrounds (per design — OLED, training-friendly)
            public static let bg = SwiftUI.Color.black
            public static let groupedBg = SwiftUI.Color.black
            public static let card = SwiftUI.Color(white: 0.11) // ~ #1C1C1E
            public static let fill = SwiftUI.Color(white: 0.20)
        #endif

        /// Accent (training)
        public static let accent = SwiftUI.Color(hex: "FF9500")

        /// AI accent — purple. Used by AIRecommendationCard + "AI 推荐"
        /// SectionHeader. Single source per Round 1 UI-§3-P2.
        public static let ai = SwiftUI.Color(hex: "7C5CFF")

        /// "Training is currently active" semantic colour. Used by the
        /// minimised training banner, live-workout pulse dot, "完成本组"
        /// CTA. Single source per Round 1 UI-§3-P0 — was 9× hard-coded
        /// `Color.orange` across LiveWorkoutView / RootView / TodayView.
        ///
        /// Distinct from `accent` (GoalTheme) on purpose: Apple Watch /
        /// Strava / Apple Fitness all use a uniform orange-red for the
        /// "in progress" state regardless of the user's other theming.
        /// Keeping this colour token-managed but NOT goal-themed.
        public static let training = SwiftUI.Color(hex: "FF9500")

        // Status (rep met/borderline/failed)
        public static let success = SwiftUI.Color(hex: "30D158")
        public static let warning = SwiftUI.Color(hex: "FF9F0A")
        public static let danger = SwiftUI.Color(hex: "FF453A")

        /// Data palette — only these 5 colors appear in charts. No exceptions.
        public enum Data {
            public static let heartRate = SwiftUI.Color(hex: "FF3B30") // 心率
            public static let velocity = SwiftUI.Color(hex: "0A84FF") // 速度
            public static let volume = SwiftUI.Color(hex: "FF9500") // 训练量
            public static let velocityLoss = SwiftUI.Color(hex: "BF5AF2") // VL%
            public static let sleep = SwiftUI.Color(hex: "5E5CE6") // 睡眠
        }
    }

    // MARK: - Spacing (4-pt scale)

    public enum Space {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32
    }

    // MARK: - Radius

    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let card: CGFloat = 14
    }

    // MARK: - Font

    public enum Font {
        // Text styles — Dynamic Type aware
        public static let largeTitle = SwiftUI.Font.system(size: 34, weight: .bold, design: .default)
        public static let title = SwiftUI.Font.system(size: 28, weight: .bold, design: .default)
        public static let headline = SwiftUI.Font.system(size: 17, weight: .semibold, design: .default)
        public static let body = SwiftUI.Font.system(size: 17, weight: .regular, design: .default)
        public static let callout = SwiftUI.Font.system(size: 15, weight: .regular, design: .default)
        public static let footnote = SwiftUI.Font.system(size: 13, weight: .regular, design: .default)
        public static let caption = SwiftUI.Font.system(size: 12, weight: .medium, design: .default)

        // Numerics — SF Pro Rounded for stat displays
        public static let numericXL = SwiftUI.Font.system(size: 72, weight: .bold, design: .rounded)
        public static let numericLarge = SwiftUI.Font.system(size: 56, weight: .semibold, design: .rounded)
        public static let numericMedium = SwiftUI.Font.system(size: 28, weight: .semibold, design: .rounded)
        public static let numericSmall = SwiftUI.Font.system(size: 17, weight: .semibold, design: .rounded)
    }
}
