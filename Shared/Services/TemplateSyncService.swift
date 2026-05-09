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
}
