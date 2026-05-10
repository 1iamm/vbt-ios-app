// WatchNavigation.swift
// VBTrainer · watchOS · 2026-05
//
// Centralized NavigationPath driver for Watch screens.

import Foundation
import SwiftUI

public enum WatchRoute: Hashable, Identifiable {
    // V1 routes — kept for backward compatibility during V2 rollout. Most are
    // unreached after V2 ships and will be removed in the cleanup commit.
    case readiness
    case cmjCountdown
    case cmjGo
    case cmjResult(attempts: [Double])
    case exercisePicker
    case weightInput(exerciseId: String)
    case liveWorkout(exerciseId: String, weightKg: Double)
    case rest(secondsRemaining: Int)
    case summary
    case planProgress
    case planNext
    case prCelebration(title: String, value: String)
    case vlStopWarning(vl: Double, threshold: Double)
    case rpeInput

    // V2 routes — phone-driven main flow.
    case syncIdle
    case planSynced
    case setReady
    case setResult
    case workoutDone

    public var id: String {
        switch self {
        case .readiness:                       return "readiness"
        case .cmjCountdown:                    return "cmjCountdown"
        case .cmjGo:                           return "cmjGo"
        case .cmjResult(let a):                return "cmjResult\(a)"
        case .exercisePicker:                  return "exercisePicker"
        case .weightInput(let id):             return "weightInput\(id)"
        case .liveWorkout(let id, let w):      return "live\(id)\(w)"
        case .rest(let s):                     return "rest\(s)"
        case .summary:                         return "summary"
        case .planProgress:                    return "planProgress"
        case .planNext:                        return "planNext"
        case .prCelebration(let t, let v):     return "pr\(t)\(v)"
        case .vlStopWarning(let v, let t):     return "vl\(v)\(t)"
        case .rpeInput:                        return "rpe"
        case .syncIdle:                        return "syncIdle"
        case .planSynced:                      return "planSynced"
        case .setReady:                        return "setReady"
        case .setResult:                       return "setResult"
        case .workoutDone:                     return "workoutDone"
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
