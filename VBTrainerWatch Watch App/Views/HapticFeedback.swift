// HapticFeedback.swift
// VBTrainer · watchOS · 2026-05
//
// 4-tier rep-completion haptic feedback per PRD §M5 + stage haptics for
// set-end / workout-end. Cross-platform safe: no-op on non-watch builds so
// unit tests can call it.

import Foundation

#if canImport(WatchKit)
import WatchKit
#endif

public enum HapticFeedback {

    /// Minimum spacing between rep haptics. watchOS itself drops play() calls
    /// fired < ~200ms apart; throttling on our side makes the drop deterministic
    /// rather than letting the system silently lose them. Weber's-law floor on
    /// human wrist discrimination is also ~200ms so users can't tell.
    private static let repThrottle: TimeInterval = 0.18

    /// UserDefaults key holding the iPhone-side `Profile.vibrationEnabled`
    /// preference, mirrored to watch via ConnectivityMessage.preferences.
    /// Missing key defaults to ON (first-launch must not be silent).
    private static let prefKey = "watch.enableRepHaptic"

    private static var lastRepFireAt: Date?

    public static func rep(_ status: MetStatus) {
        guard isRepHapticEnabled() else { return }
        let now = Date()
        if let last = lastRepFireAt, now.timeIntervalSince(last) < repThrottle {
            return
        }
        lastRepFireAt = now
        #if canImport(WatchKit)
        let pattern: WKHapticType
        switch status {
        case .excellent:  pattern = .success
        case .met:        pattern = .directionUp
        case .borderline: pattern = .directionDown
        case .failed:     pattern = .failure
        }
        WKInterfaceDevice.current().play(pattern)
        #endif
    }

    /// Single set finished — distinct from rep haptic so user can feel "组结束".
    /// Not gated by `enableRepHaptic` (stage markers should always fire).
    public static func setEnded() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.stop)
        #endif
    }

    /// Whole workout finished — single `.success` (not double; watchOS drops
    /// the 2nd play() within ~200ms of the 1st).
    public static func workoutEnded() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.success)
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

    private static func isRepHapticEnabled() -> Bool {
        if let stored = UserDefaults.standard.object(forKey: prefKey) as? Bool {
            return stored
        }
        return true
    }
}
