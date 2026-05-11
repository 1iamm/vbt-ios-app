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

    /// When true, the fullScreenCover is dismissed but the session is still
    /// active. TodayView shows a compact banner the user can tap to expand
    /// the cover back open. Reset on workout end.
    @Published public var isMinimized: Bool = false

    public init() {}

    /// User tapped the minimize chevron — keep session active, hide cover.
    public func minimize() { isMinimized = true }

    /// User tapped the Today banner — re-present the cover.
    public func expand() { isMinimized = false }

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
        isMinimized = false
    }

    /// Optimistic local nudge for ±10s / skip presses on iPhone. WC delivery
    /// can lag a couple seconds on simulator; without this the iPhone RestView
    /// looks unresponsive until the Watch's next tick echoes back. The Watch's
    /// authoritative push will overwrite shortly.
    public func optimisticRestAdjust(deltaSeconds: Int) {
        guard let p = payload, p.phase == .restCountdown else { return }
        let curR = p.restRemainingSec ?? 0
        let curT = p.restTotalSec ?? curR
        let newR = max(0, min(600, curR + deltaSeconds))
        let newT = max(5, min(600, curT + deltaSeconds))
        payload = LiveProgressPayload(
            phase: p.phase,
            workoutId: p.workoutId,
            setIndex: p.setIndex,
            exerciseName: p.exerciseName,
            targetReps: p.targetReps,
            targetWeightKg: p.targetWeightKg,
            currentRep: p.currentRep,
            lastRepVelocity: p.lastRepVelocity,
            setBestVelocity: p.setBestVelocity,
            vlPercent: p.vlPercent,
            repVelocities: p.repVelocities,
            restRemainingSec: newR,
            restTotalSec: newT,
            heartRate: p.heartRate,
            timestamp: Date()
        )
    }
}
