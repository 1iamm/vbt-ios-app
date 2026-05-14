// VBTrainerWatchApp.swift
// VBTrainer · watchOS App entry · 2026-05

import SwiftData
import SwiftUI

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
        // Request HealthKit authorization up-front so HKWorkoutSession can be
        // created the moment the user starts a workout (otherwise MotionManager
        // throws and 100Hz CoreMotion is throttled).
        Task { try? await HealthKitAuthorization.requestWorkoutAuthorization() }
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
        .modelContainer(container)
    }
}
