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
    }

    @ViewBuilder
    private func routeView(_ route: WatchRoute) -> some View {
        switch route {
        case .readiness:
            WatchReadinessView()
        case .cmjCountdown:
            WatchCMJCountdownView()
        case .cmjGo:
            WatchCMJGoView()
        case .cmjResult(let attempts):
            WatchCMJResultView(attempts: attempts)
        case .exercisePicker:
            WatchExercisePickerView()
        case .weightInput(let id):
            WatchWeightInputView(exerciseId: id)
        case .liveWorkout(let id, let w):
            WatchLiveWorkoutView(exerciseId: id, weightKg: w)
        case .rest(let s):
            WatchRestView(secondsRemaining: s)
        case .summary:
            WatchSummaryView()
        case .planProgress:
            WatchPlanProgressView()
        case .planNext:
            WatchPlanNextView()
        case .prCelebration(let t, let v):
            WatchPRCelebrationView(title: t, value: v)
        case .vlStopWarning(let vl, let th):
            WatchVLStopWarningView(vl: vl, threshold: th)
        case .rpeInput:
            WatchRPEInputView()
        // V2 routes
        case .syncIdle:
            SyncIdleView()
        case .planSynced:
            PlanSyncedView()
        case .setReady:
            SetReadyView()
        case .setResult:
            SetResultView()
        case .workoutDone:
            WorkoutDoneView()
        }
    }
}

#Preview {
    WatchRootView()
}
