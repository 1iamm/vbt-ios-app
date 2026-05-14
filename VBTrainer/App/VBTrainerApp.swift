// VBTrainerApp.swift
// VBTrainer · iPhone App entry · 2026-05

import OSLog
import SwiftData
import SwiftUI

@main
struct VBTrainerApp: App {
    /// SwiftData container with crash-safety (Round 2 Reliability #17):
    ///   1. Try opening the real on-disk store.
    ///   2. On failure → log + rename the broken store to
    ///      `default.store.broken-<timestamp>` and retry on a fresh empty
    ///      container.
    ///   3. If retry still fails → fall back to in-memory only.
    ///
    /// Old code did `fatalError("ModelContainer init failed: \(error)")` →
    /// TestFlight / App Store users get instant crash on schema mismatch
    /// / disk full / iCloud Drive lock contention. This sidelines (not
    /// deletes) the broken store so a future JSONImporter restore can
    /// recover the user's data.
    let container: ModelContainer = makeContainer()

    static func makeContainer() -> ModelContainer {
        let schema = Schema(VBTSchemaV1.allModels)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        // Attempt 1: real on-disk store.
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            return c
        }

        log.error("ModelContainer init failed — sidelining broken store and retrying")

        // Attempt 2: rename the broken store, try again on fresh disk state.
        sidelineBrokenStore()
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            log.notice("ModelContainer recovered after sidelining broken store")
            return c
        }

        // Attempt 3: in-memory only. User keeps the session usable but
        // nothing persists. Better than crashing the app.
        log.fault("ModelContainer fell back to in-memory after recovery failed")
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [memConfig])
    }

    /// Rename SwiftData's default store files (`default.store`,
    /// `default.store-shm`, `default.store-wal`) to
    /// `default.store.broken-<timestamp>{,-shm,-wal}`. Forces fresh init
    /// next attempt; preserves user data on disk for later recovery.
    private static func sidelineBrokenStore() {
        let fm = FileManager.default
        guard let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }
        let ts = Int(Date().timeIntervalSince1970)
        for suffix in ["", "-shm", "-wal"] {
            let src = appSupport.appendingPathComponent("default.store\(suffix)")
            guard fm.fileExists(atPath: src.path) else { continue }
            let dst = appSupport.appendingPathComponent("default.store.broken-\(ts)\(suffix)")
            do {
                try fm.moveItem(at: src, to: dst)
                log.notice("Sidelined \(src.lastPathComponent) → \(dst.lastPathComponent)")
            } catch {
                log.error("Failed to sideline \(src.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    private static let log = Logger(subsystem: "com.vbtrainer.app", category: "ModelContainer")

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
