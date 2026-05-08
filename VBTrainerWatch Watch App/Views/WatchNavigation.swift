// WatchNavigation.swift
// VBTrainer · watchOS · 2026-05
//
// Centralized NavigationPath driver for Watch screens.

import Foundation
import SwiftUI

public enum WatchRoute: Hashable, Identifiable {
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
}
