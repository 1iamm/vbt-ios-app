// LiveWorkoutStore.swift
// VBTrainer · iOS · 2026-05
//
// Singleton @MainActor ObservableObject that holds the latest
// LiveProgressPayload pushed from the Watch during a training session.
// TodayView observes `isLive` to present the fullScreenCover and
// LiveWorkoutView reads `payload` to render the current phase.
//
// Per Round-3 PM consensus: in-memory only, no persistence (V2 may add
// crash-recovery via UserDefaults cache).

import Foundation
import SwiftUI

@available(iOS 17.0, *)
@MainActor
public final class LiveWorkoutStore: ObservableObject {

    public static let shared = LiveWorkoutStore()

    /// Latest payload received. Nil until first .ready message arrives.
    @Published public private(set) var payload: LiveProgressPayload?

    /// True when a training session is currently active (between .ready and
    /// .workoutEnded). TodayView binds fullScreenCover.isPresented to this.
    @Published public private(set) var isLive: Bool = false

    public init() {}

    /// Apply a payload received from the Watch. Old payloads (older
    /// timestamp than current) are ignored — protects against out-of-order
    /// transferUserInfo deliveries.
    public func apply(_ p: LiveProgressPayload) {
        if let current = payload, current.timestamp > p.timestamp {
            #if DEBUG
            print("[LiveStore] dropping stale payload phase=\(p.phase) ts=\(p.timestamp) < current=\(current.timestamp)")
            #endif
            return
        }
        payload = p
        switch p.phase {
        case .ready, .repDetected, .setEnded, .restCountdown:
            isLive = true
        case .workoutEnded:
            // Keep payload around briefly so view can show end animation,
            // but mark inactive immediately so cover dismisses.
            isLive = false
        }
        #if DEBUG
        print("[LiveStore] apply phase=\(p.phase.rawValue) rep=\(p.currentRep)/\(p.targetReps) v=\(p.lastRepVelocity ?? -1)")
        #endif
    }

    /// Force-clear the store (e.g. when user manually exits the cover).
    public func clear() {
        payload = nil
        isLive = false
    }
}
