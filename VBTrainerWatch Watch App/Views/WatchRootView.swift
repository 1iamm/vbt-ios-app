// WatchRootView.swift
// VBTrainer · watchOS · 2026-05
//
// Root navigation host. Owns the WatchNavigation observable, hosts a
// NavigationStack, and routes WatchRoute values to their views.

import SwiftUI

struct WatchRootView: View {
    @StateObject private var nav = WatchNavigation()
    @StateObject private var liveController = LiveWorkoutController()

    var body: some View {
        NavigationStack(path: $nav.path) {
            SyncIdleView()
                .navigationDestination(for: WatchRoute.self) { route in
                    routeView(route)
                }
        }
        .environmentObject(nav)
        .environmentObject(liveController)
        .task {
            // Restore any in-flight workout cursor that survived an app kill.
            liveController.restoreFromCursorIfPossible()
        }
        .onReceive(NotificationCenter.default.publisher(for: .vbtWatchActivated)) { _ in
            // iPhone pushed `.startWorkout` — pop to root and jump to PlanSynced.
            nav.popToRoot()
            nav.push(.planSynced)
        }
        .onReceive(NotificationCenter.default.publisher(for: .vbtVLCeilingExceeded)) { note in
            let vl = note.userInfo?["vl"] as? Double ?? 0
            let th = note.userInfo?["threshold"] as? Double ?? 0
            nav.push(.vlStopWarning(vl: vl, threshold: th))
        }
    }

    @ViewBuilder
    private func routeView(_ route: WatchRoute) -> some View {
        switch route {
        case .syncIdle:
            SyncIdleView()
        case .planSynced:
            PlanSyncedView()
        case .setReady:
            SetReadyView()
        case let .liveWorkout(id, w):
            WatchLiveWorkoutView(exerciseId: id, weightKg: w)
        case .setResult:
            SetResultView()
        case let .rest(s):
            WatchRestView(secondsRemaining: s)
        case .workoutDone:
            WorkoutDoneView()
        case .readiness:
            WatchReadinessView()
        case .summary:
            WatchSummaryView()
        case let .prCelebration(t, v):
            WatchPRCelebrationView(title: t, value: v)
        case let .vlStopWarning(vl, th):
            WatchVLStopWarningView(vl: vl, threshold: th)
        case .rpeInput:
            WatchRPEInputView()
        }
    }
}

#Preview {
    WatchRootView()
}
