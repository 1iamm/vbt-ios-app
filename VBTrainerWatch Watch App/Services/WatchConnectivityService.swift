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
        #if DEBUG
        print("[WC] watch send ENTER kind=\(message.kind.rawValue)")
        #endif
        guard WCSession.isSupported() else {
            #if DEBUG
            print("[WC] watch send ABORT WCSession.isSupported=false")
            #endif
            return
        }
        let session = WCSession.default
        #if DEBUG
        print("[WC] watch send state activationState=\(session.activationState.rawValue) isReachable=\(session.isReachable) isCompanionAppInstalled=\(session.isCompanionAppInstalled)")
        #endif
        guard session.activationState == .activated else {
            #if DEBUG
            print("[WC] watch send ABORT activationState != .activated (\(session.activationState.rawValue))")
            #endif
            // Re-activate so subsequent sends work after a transient
            // deactivation (e.g. iPhone app cold-launch race).
            session.delegate = self
            session.activate()
            return
        }
        do {
            let userInfo = try ConnectivityCodec.encode(message)
            // 模拟器里 isReachable 经常误报 false，所以无视它直接试
            // sendMessage。errorHandler 回落到 transferUserInfo 兜底。
            #if DEBUG
            print("[WC] watch send via sendMessage (isReachable=\(session.isReachable))")
            #endif
            session.sendMessage(userInfo, replyHandler: { _ in
                #if DEBUG
                print("[WC] watch sendMessage reply received")
                #endif
            }) { error in
                #if DEBUG
                print("[WC] watch sendMessage failed, falling back to transferUserInfo: \(error.localizedDescription)")
                #endif
                session.transferUserInfo(userInfo)
            }
        } catch {
            #if DEBUG
            print("[WC] watch send encode error: \(error)")
            #endif
        }
    }

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        #if DEBUG
        print("[WC] watch activationDidComplete state=\(activationState.rawValue) error=\(error?.localizedDescription ?? "nil") isReachable=\(session.isReachable)")
        #endif
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        #if DEBUG
        print("[WC] watch didReceiveUserInfo keys=\(userInfo.keys)")
        #endif
        Task { @MainActor in
            await Self.handleInbound(userInfo)
        }
    }

    /// `sendMessage` path — used by the iPhone side's V2 activation flow so the
    /// caller can show a spinner until we reply. The reply payload is empty;
    /// what matters is that the call completes, signalling delivery.
    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        #if DEBUG
        print("[WC] watch didReceiveMessage keys=\(message.keys)")
        #endif
        Task { @MainActor in
            await Self.handleInbound(message)
        }
        replyHandler([:])
    }

    /// Shared decode + dispatch for both `transferUserInfo` and `sendMessage`
    /// inbound paths. `@MainActor` because all downstream stores / centers are.
    @MainActor
    private static func handleInbound(_ userInfo: [String: Any]) async {
        do {
            guard let message = try ConnectivityCodec.decode(userInfo) else { return }
            switch message {
            case .template(let snap):
                TodayPlanStore.shared.store(snap)
            case .preferences(let prefs):
                UserDefaults.standard.set(prefs.enableRepHaptic, forKey: "watch.enableRepHaptic")
            case .startWorkout(let snap):
                // V2.1: bundled template — store before activation so PlanSynced
                // sees data the moment WatchRootView pushes it.
                if let bundled = snap.template {
                    TodayPlanStore.shared.store(bundled)
                }
                WatchActivationCenter.shared.activate(snap)
            default:
                // Other inbound message kinds — Watch doesn't yet handle.
                break
            }
        } catch {
            #if DEBUG
            print("[WC] watch decode error: \(error)")
            #endif
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
