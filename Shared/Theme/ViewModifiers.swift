// ViewModifiers.swift
// VBTrainer · Shared theme · 2026-05
//
// Reusable view modifiers built on Tokens. Extracted per Round 1 UI audit
// finding UI-§5-P1: 39 hand-rolled `Tokens.Color.card, in: RoundedRectangle(
// cornerRadius: 14)` chains across the codebase made design-token changes
// a 39-file hunt. Centralising here is single-point-of-change.

import SwiftUI

public extension View {
    /// Standard VBTrainer card chrome: `Tokens.Color.card` background fill +
    /// rounded-rectangle clip. Default radius matches `Tokens.Radius.card`
    /// (14pt); pass a different value for non-default cards (e.g. 12pt mini
    /// cards or 16pt large hero cards).
    ///
    /// Replaces the inline form:
    /// ```swift
    /// .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
    /// ```
    /// with:
    /// ```swift
    /// .cardStyle()
    /// ```
    func cardStyle(cornerRadius: CGFloat = Tokens.Radius.card) -> some View {
        background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
