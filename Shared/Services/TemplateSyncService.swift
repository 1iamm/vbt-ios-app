// TemplateSyncService.swift
// VBTrainer · 2026-05
//
// Builds a TemplateSnapshot from the SwiftData template + scheduled date,
// pushes to Watch via WCSession.

import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@available(iOS 17.0, watchOS 10.0, *)
public enum TemplateSyncService {

    public static func snapshot(of template: Template, on date: Date) -> TemplateSnapshot {
        let day = Calendar.current.startOfDay(for: date)
        let items: [TemplateItemSnapshot] = template.items
            .sorted(by: { $0.index < $1.index })
            .map { item in
                let specs: [TemplateSetSpecSnapshot] = item.orderedSetSpecs.map { s in
                    TemplateSetSpecSnapshot(
                        id: s.id,
                        index: s.index,
                        kindRaw: s.kind.rawValue,
                        weightKg: s.weightKg,
                        reps: s.reps,
                        restSeconds: s.restSeconds
                    )
                }
                return TemplateItemSnapshot(
                    id: item.id,
                    index: item.index,
                    exerciseId: item.exerciseId,
                    targetSets: item.targetSets,
                    targetReps: item.targetReps,
                    targetWeightKg: item.targetWeightKg,
                    targetVelocityMin: item.targetVelocityMin,
                    targetVelocityMax: item.targetVelocityMax,
                    vlCeiling: item.vlCeiling,
                    restSeconds: item.restSeconds,
                    sideRaw: item.sideRaw,
                    setSpecs: specs
                )
            }
        return TemplateSnapshot(
            id: template.id,
            name: template.name,
            scheduledDate: day,
            items: items
        )
    }

    /// Push a template + date to the Watch.
    public static func push(template: Template, on date: Date) {
        let snap = snapshot(of: template, on: date)
        #if canImport(WatchConnectivity) && os(iOS)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        do {
            let userInfo = try ConnectivityCodec.encode(.template(snap))
            session.transferUserInfo(userInfo)
        } catch {
            #if DEBUG
            print("TemplateSyncService.push error: \(error)")
            #endif
        }
        #endif
    }

    /// V2 activation result.
    public enum ActivationResult: Sendable {
        /// Watch confirmed receipt within the timeout (`sendMessage` reply).
        case delivered
        /// Watch was unreachable; fell back to `transferUserInfo`. Will land
        /// next time the user opens the watch app.
        case queued
        /// Couldn't even queue (WCSession unsupported / inactive / encode error).
        case failed(String)
    }

    /// V2 activation, async + result-bearing variant. Tries `sendMessage` first
    /// (instant + reply confirmation), falls back to `transferUserInfo` (queued
    /// for next watch app launch). The template itself is always pushed via
    /// `transferUserInfo` (it tolerates being queued).
    ///
    /// Designed for UI that wants to show a spinner until the Watch confirms.
    /// Default 5s timeout — sendMessage in simulator is < 1s, real device < 0.5s.
    public static func pushAndStart(
        template: Template,
        on date: Date,
        startItemIndex: Int = 0,
        timeout: TimeInterval = 5
    ) async -> ActivationResult {
        // Snapshot once + push the queued copy as a fallback for the
        // watch-app-not-running case. The bundled copy in startWorkout below
        // is what makes the in-flight UI actually populate.
        let templateSnap = snapshot(of: template, on: date)
        #if canImport(WatchConnectivity) && os(iOS)
        guard WCSession.isSupported() else { return .failed("WCSession unsupported") }
        let session = WCSession.default
        // Activation is async after session.activate() — if user taps right
        // after app launch, state can still be .inactive / .notActivated.
        // Poll up to 3s for .activated before giving up. (Simulator first-
        // launch usually completes within 1s.)
        if session.activationState != .activated {
            #if DEBUG
            print("[WC] iPhone pushAndStart waiting for activation, current state=\(session.activationState.rawValue)")
            #endif
            session.activate()
            let deadline = Date().addingTimeInterval(3.0)
            while Date() < deadline && session.activationState != .activated {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            #if DEBUG
            print("[WC] iPhone pushAndStart post-wait state=\(session.activationState.rawValue)")
            #endif
        }
        guard session.activationState == .activated else {
            return .failed("Watch 还没连接好，等几秒再试")
        }
        // Push the queued template AFTER activation succeeds so the
        // transferUserInfo doesn't get dropped on the floor.
        push(template: template, on: date)
        let activation = StartWorkoutSnapshot(
            templateId: template.id,
            startItemIndex: startItemIndex,
            template: templateSnap
        )
        let userInfo: [String: Any]
        do {
            userInfo = try ConnectivityCodec.encode(.startWorkout(activation))
        } catch {
            return .failed("encode error: \(error.localizedDescription)")
        }

        #if DEBUG
        print("[WC] iPhone pushAndStart reachable=\(session.isReachable)")
        #endif

        // 1) Try sendMessage (instant + reply confirmation) when reachable
        if session.isReachable {
            let delivered = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                var resumed = false
                let lock = NSLock()
                let resume: (Bool) -> Void = { value in
                    lock.lock(); defer { lock.unlock() }
                    guard !resumed else { return }
                    resumed = true
                    cont.resume(returning: value)
                }
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    resume(false)
                }
                session.sendMessage(userInfo, replyHandler: { _ in
                    timeoutTask.cancel()
                    resume(true)
                }, errorHandler: { err in
                    #if DEBUG
                    print("[WC] iPhone sendMessage failed: \(err.localizedDescription)")
                    #endif
                    timeoutTask.cancel()
                    resume(false)
                })
            }
            if delivered {
                #if DEBUG
                print("[WC] iPhone pushAndStart .delivered")
                #endif
                return .delivered
            }
        }

        // 2) Fallback: queue via transferUserInfo (delivered on next watch launch)
        session.transferUserInfo(userInfo)
        #if DEBUG
        print("[WC] iPhone pushAndStart .queued (transferUserInfo fallback)")
        #endif
        return .queued
        #else
        return .failed("WatchConnectivity unavailable on this build")
        #endif
    }

    /// One-way iPhone → Watch push of user preferences that affect Watch
    /// behaviour (currently: rep-haptic on/off). Inlined here (rather than a
    /// separate file) so the iOS target builds without requiring
    /// `xcodegen generate` to pick up a new file.
    public static func pushPreferences(_ snapshot: WatchPreferencesSnapshot) {
        #if canImport(WatchConnectivity) && os(iOS)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        do {
            let userInfo = try ConnectivityCodec.encode(.preferences(snapshot))
            session.transferUserInfo(userInfo)
        } catch {
            #if DEBUG
            print("TemplateSyncService.pushPreferences error: \(error)")
            #endif
        }
        #endif
    }
}
