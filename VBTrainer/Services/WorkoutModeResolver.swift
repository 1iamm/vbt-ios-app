// WorkoutModeResolver.swift
// VBTrainer · iOS · 2026-05
//
// Decides whether "开始训练" routes to the Watch handoff path (which pushes
// a template + activation message and lets Watch drive IMU rep detection)
// or to the new IPhoneActiveWorkoutView (manual logging, no Watch needed).
//
// Resolution: ProfileView toggle override → WCSession pairing/install →
// default iPhone-only.

import Foundation

#if canImport(WatchConnectivity)
    import WatchConnectivity
#endif

@available(iOS 17.0, *)
public enum WorkoutModeResolver {
    private static let prefKey = "vbt.trainingModePreference"

    /// Persisted user override. Defaults to `.auto`.
    public static var preference: TrainingModePreference {
        get {
            if let raw = UserDefaults.standard.string(forKey: prefKey),
               let p = TrainingModePreference(rawValue: raw)
            {
                return p
            }
            return .auto
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: prefKey)
        }
    }

    /// Whether the Watch is currently paired AND VBTrainer.watchkit is installed.
    /// Returns false on simulator without paired watch and on devices that
    /// never set up a Watch.
    public static var hasWatch: Bool {
        #if canImport(WatchConnectivity) && os(iOS)
            guard WCSession.isSupported() else { return false }
            let session = WCSession.default
            return session.isPaired && session.isWatchAppInstalled
        #else
            return false
        #endif
    }

    /// Whether the Watch app is *right now* reachable for an instant
    /// `sendMessage(...)` activation. False when the Watch is asleep / off
    /// the wrist / Bluetooth lost — even though the Watch is paired and
    /// VBTrainer is installed (i.e. `hasWatch == true`).
    ///
    /// Used by Today to decide whether to silently route auto-mode to Watch
    /// (reachable) or pop the iPhone-vs-Watch dialog (unreachable).
    public static var isWatchReachable: Bool {
        #if canImport(WatchConnectivity) && os(iOS)
            guard WCSession.isSupported() else { return false }
            let session = WCSession.default
            return session.isReachable
        #else
            return false
        #endif
    }

    /// The effective source the next workout will use.
    public static var effectiveSource: WorkoutSource {
        switch preference {
        case .forceWatch: .watch
        case .forceIPhone: .iPhone
        case .auto: hasWatch ? .watch : .iPhone
        }
    }

    /// Short label for the Profile section showing the user what 「自动」will pick.
    public static var autoResolutionLabel: String {
        hasWatch ? "已检测到 Apple Watch" : "未检测到 Apple Watch"
    }
}
