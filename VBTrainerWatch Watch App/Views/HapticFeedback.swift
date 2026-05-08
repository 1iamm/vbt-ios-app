// HapticFeedback.swift
// VBTrainer · watchOS · 2026-05
//
// 4-tier rep-completion haptic feedback per PRD §M5.
// Cross-platform safe: no-op on non-watch builds so unit tests can call it.

import Foundation

#if canImport(WatchKit)
import WatchKit
#endif

public enum HapticFeedback {

    public static func rep(_ status: MetStatus) {
        #if canImport(WatchKit)
        let pattern: WKHapticType
        switch status {
        case .excellent:  pattern = .success
        case .met:        pattern = .click
        case .borderline: pattern = .directionUp
        case .failed:     pattern = .failure
        }
        WKInterfaceDevice.current().play(pattern)
        #endif
    }

    public static func restEnded() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.start)
        #endif
    }

    public static func vlCeilingExceeded() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.failure)
        #endif
    }

    public static func notification() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.notification)
        #endif
    }
}
