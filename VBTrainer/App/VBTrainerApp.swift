// VBTrainerApp.swift
// VBTrainer · iPhone App entry · 2026-05

import SwiftData
import SwiftUI

@main
struct VBTrainerApp: App {
    let container: ModelContainer = {
        do {
            let schema = Schema(VBTSchemaV1.allModels)
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }
    }()

    init() {
        iPhoneConnectivityService.shared.bind(container: container)
        let containerRef = container
        Task { @MainActor in
            // Start reverse-sync watcher (no-op until user grants Calendar access).
            DayPlanReverseSyncer.shared.bind(container: containerRef)
            // Roll past-due scheduled plans to .missed and migrate any legacy
            // completed flags into the new status enum on every cold launch.
            let context = ModelContext(containerRef)
            DayPlanStateMachine.backfillLegacyCompleted(in: context)
            DayPlanStateMachine.reconcileMissed(in: context)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
