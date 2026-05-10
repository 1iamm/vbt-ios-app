// WatchActivationCenter.swift
// VBTrainer · watchOS · 2026-05
//
// Buffers iPhone-side `.startWorkout` activation signals between the
// connectivity layer (off main actor) and SwiftUI's WatchRootView. Posts
// `.vbtWatchActivated` so root can pop to root and jump to PlanSynced.

import Foundation

@MainActor
public final class WatchActivationCenter: ObservableObject {

    public static let shared = WatchActivationCenter()

    @Published public private(set) var pending: StartWorkoutSnapshot?

    public init() {}

    /// Called by `WatchConnectivityService` when an inbound `.startWorkout`
    /// message decodes. Buffers the snapshot and notifies the navigation host.
    public func activate(_ snapshot: StartWorkoutSnapshot) {
        pending = snapshot
        NotificationCenter.default.post(name: .vbtWatchActivated, object: snapshot.templateId)
    }

    /// Read + clear. Used by the navigation host once it has consumed the
    /// activation (e.g. after popping to root and pushing planSynced).
    public func consume() -> StartWorkoutSnapshot? {
        let snap = pending
        pending = nil
        return snap
    }
}
