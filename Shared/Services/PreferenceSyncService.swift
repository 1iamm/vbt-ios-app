// PreferenceSyncService.swift
// VBTrainer · 2026-05
//
// One-way iPhone → Watch push of user preferences that affect Watch behaviour
// (currently: rep-haptic on/off). Mirrors the TemplateSyncService.push pattern.

import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@available(iOS 17.0, watchOS 10.0, *)
public enum PreferenceSyncService {

    public static func push(_ snapshot: WatchPreferencesSnapshot) {
        #if canImport(WatchConnectivity) && os(iOS)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        do {
            let userInfo = try ConnectivityCodec.encode(.preferences(snapshot))
            session.transferUserInfo(userInfo)
        } catch {
            #if DEBUG
            print("PreferenceSyncService.push error: \(error)")
            #endif
        }
        #endif
    }
}
