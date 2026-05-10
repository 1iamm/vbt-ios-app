// WatchConnectivityService.swift
// VBTrainer · watchOS · 2026-05
//
// Watch-side WCSession wrapper. Activates the session on init and exposes
// `send(...)` for buffered transfer (transferUserInfo) so the message
// survives app background.

import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity

/// Buffers iPhone-side `.startWorkout` activation signals between the
/// connectivity layer (off main actor) and SwiftUI's WatchRootView. Posts
/// `.vbtWatchActivated` so root can pop to root and jump to PlanSynced.
///
/// Inlined here (rather than a standalone file) so the watch target builds
/// without requiring `xcodegen generate` to pick up a new file.
@MainActor
public final class WatchActivationCenter: ObservableObject {

    public static let shared = WatchActivationCenter()

    @Published public private(set) var pending: StartWorkoutSnapshot?

    public init() {}

    public func activate(_ snapshot: StartWorkoutSnapshot) {
        pending = snapshot
        NotificationCenter.default.post(name: .vbtWatchActivated, object: snapshot.templateId)
    }

    public func consume() -> StartWorkoutSnapshot? {
        let snap = pending
        pending = nil
        return snap
    }
}

public final class WatchConnectivityService: NSObject, WCSessionDelegate {

    public static let shared = WatchConnectivityService()

    public override init() {
        super.init()
        activate()
    }

    public func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    public func send(message: ConnectivityMessage) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        do {
            let userInfo = try ConnectivityCodec.encode(message)
            session.transferUserInfo(userInfo)
        } catch {
            #if DEBUG
            print("WatchConnectivityService.send encode error: \(error)")
            #endif
        }
    }

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No-op
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            do {
                guard let message = try ConnectivityCodec.decode(userInfo) else { return }
                switch message {
                case .template(let snap):
                    TodayPlanStore.shared.store(snap)
                case .preferences(let prefs):
                    UserDefaults.standard.set(prefs.enableRepHaptic, forKey: "watch.enableRepHaptic")
                case .startWorkout(let snap):
                    WatchActivationCenter.shared.activate(snap)
                default:
                    // Other inbound message kinds — Watch doesn't yet handle.
                    break
                }
            } catch {
                #if DEBUG
                print("Watch didReceiveUserInfo decode error: \(error)")
                #endif
            }
        }
    }
}
#else
// On platforms without WatchConnectivity (e.g. some tests / preview targets)
// we provide an inert stub so shared call sites compile.
public final class WatchConnectivityService {
    public static let shared = WatchConnectivityService()
    private init() {}
    public func activate() {}
    public func send(message: ConnectivityMessage) {}
}
#endif
