// Color+Hex.swift
// VBTrainer · 2026-05
//
// Hex color initializer — used for tokens that the design system requires
// to match the Claude Design source-of-truth exactly (see vbt-tokens.jsx).
// Neutral colors (label / secondaryLabel / bg) DO NOT use this; they go
// through SwiftUI semantic colors so they auto-adapt to light/dark mode.

import SwiftUI

extension Color {
    /// Initialize from a 6-digit hex string, with or without the leading "#".
    /// Returns gray on malformed input rather than crashing.
    init(hex raw: String) {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16) else {
            self = .gray
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8)  & 0xFF) / 255.0
        let b = Double( value        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
