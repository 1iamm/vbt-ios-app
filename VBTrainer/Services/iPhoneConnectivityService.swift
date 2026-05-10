// iPhoneConnectivityService.swift
// VBTrainer · iOS · 2026-05
//
// iPhone-side WCSession wrapper. Receives messages, routes to stores,
// posts NotificationCenter signals so SwiftUI can refresh.

import Foundation
import SwiftData

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@available(iOS 17.0, *)
public final class iPhoneConnectivityService: NSObject {

    public static let shared = iPhoneConnectivityService()

    private var modelContainer: ModelContainer?

    public func bind(container: ModelContainer) {
        self.modelContainer = container
    }

    public override init() {
        super.init()
        activate()
    }

    public func activate() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #endif
    }
}

#if canImport(WatchConnectivity)
extension iPhoneConnectivityService: WCSessionDelegate {

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No-op
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            await handle(userInfo: userInfo)
        }
    }

    @MainActor
    private func handle(userInfo: [String: Any]) async {
        guard let container = modelContainer else { return }
        do {
            guard let message = try ConnectivityCodec.decode(userInfo) else { return }
            let context = ModelContext(container)
            switch message {
            case .workoutSnapshot(let snap):
                let workout = try WorkoutStore.save(snap, in: context)
                PersonalRecordDetector.checkAndRecord(workout: workout, in: context)
                // Drive the DayPlan state machine — match this workout to a
                // scheduled plan on the same calendar day and mark it
                // completed. No-op if no plan exists.
                DayPlanStateMachine.markCompleted(
                    for: workout.id,
                    workoutDay: workout.startedAt,
                    in: context
                )
                NotificationCenter.default.post(name: .vbtWorkoutImported, object: snap.id)
            case .jumpTest(let jumpSnap):
                _ = JumpTestStore.save(
                    attempts: jumpSnap.attempts,
                    flightTimes: jumpSnap.flightTimeSeconds,
                    linkedWorkoutId: jumpSnap.linkedWorkoutId,
                    in: context
                )
                NotificationCenter.default.post(name: .vbtJumpTestImported, object: jumpSnap.id)
            case .template:
                // iPhone is the source-of-truth for templates; inbound from
                // Watch isn't expected in V1.
                break
            case .preferences:
                // iPhone authors the preference; inbound from Watch isn't
                // expected (Watch only consumes via UserDefaults cache).
                break
            case .startWorkout:
                // iPhone sends activation signals to Watch; inbound from
                // Watch isn't expected.
                break
            }
        } catch {
            #if DEBUG
            print("iPhoneConnectivityService decode/save error: \(error)")
            #endif
        }
    }
}
#endif
