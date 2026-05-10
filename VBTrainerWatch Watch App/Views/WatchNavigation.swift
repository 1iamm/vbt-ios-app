// WatchNavigation.swift
// VBTrainer · watchOS · 2026-05
//
// Centralized NavigationPath driver for Watch screens.

import Foundation
import SwiftUI

public enum WatchRoute: Hashable, Identifiable {
    // V2 main flow (phone-driven).
    case syncIdle
    case planSynced
    case setReady
    case liveWorkout(exerciseId: String, weightKg: Double)
    case setResult
    case rest(secondsRemaining: Int)
    case workoutDone

    // Carryover screens still used by V2: readiness (iPhone push) + summary
    // (RPE / Feeling subjective evaluation, distinct from per-set SetResult)
    // + event overlays (PR celebration, VL stop warning).
    case readiness
    case summary
    case prCelebration(title: String, value: String)
    case vlStopWarning(vl: Double, threshold: Double)
    case rpeInput

    public var id: String {
        switch self {
        case .syncIdle:                        return "syncIdle"
        case .planSynced:                      return "planSynced"
        case .setReady:                        return "setReady"
        case .liveWorkout(let id, let w):      return "live\(id)\(w)"
        case .setResult:                       return "setResult"
        case .rest(let s):                     return "rest\(s)"
        case .workoutDone:                     return "workoutDone"
        case .readiness:                       return "readiness"
        case .summary:                         return "summary"
        case .prCelebration(let t, let v):     return "pr\(t)\(v)"
        case .vlStopWarning(let v, let t):     return "vl\(v)\(t)"
        case .rpeInput:                        return "rpe"
        }
    }
}

@MainActor
public final class WatchNavigation: ObservableObject {
    @Published public var path = NavigationPath()

    public init() {}

    public func push(_ route: WatchRoute) {
        path.append(route)
    }

    public func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    public func popToRoot() {
        path = NavigationPath()
    }

    /// Replace top-of-stack: pops the current top, then pushes `route`. Used by
    /// auto-advancing screens (SetResult → Rest, Rest countdown → SetReady) so
    /// the back stack doesn't pile up.
    public func replaceTop(with route: WatchRoute) {
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }
}
