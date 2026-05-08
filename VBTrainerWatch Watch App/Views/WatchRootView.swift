// WatchRootView.swift
// VBTrainer · watchOS · 2026-05
//
// Root navigation host. Owns the WatchNavigation observable, hosts a
// NavigationStack, and routes WatchRoute values to their views.

import SwiftUI

struct WatchRootView: View {
    @StateObject private var nav = WatchNavigation()

    var body: some View {
        NavigationStack(path: $nav.path) {
            WatchHomeView()
                .navigationDestination(for: WatchRoute.self) { route in
                    routeView(route)
                }
        }
        .environmentObject(nav)
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
        }
    }
}

#Preview {
    WatchRootView()
}
