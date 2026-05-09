// VBTrainerApp.swift
// VBTrainer · iPhone App entry · 2026-05

import SwiftUI
import SwiftData

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
        // Start reverse-sync watcher (no-op until user grants Calendar access).
        Task { @MainActor in
            DayPlanReverseSyncer.shared.bind(container: container)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
