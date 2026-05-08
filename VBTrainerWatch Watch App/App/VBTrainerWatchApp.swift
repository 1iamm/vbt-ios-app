// VBTrainerWatchApp.swift
// VBTrainer · watchOS App entry · 2026-05

import SwiftUI
import SwiftData

@main
struct VBTrainerWatchApp: App {

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
        // Activate WCSession on launch.
        _ = WatchConnectivityService.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
        .modelContainer(container)
    }
}
