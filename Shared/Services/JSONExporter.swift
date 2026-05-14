// JSONExporter.swift
// VBTrainer · 2026-05
//
// Full structured backup of the user's local data. Round-trips with
// future Import logic (Proposal V2).

import Foundation
import SwiftData

public struct VBTBackup: Codable, Sendable {
    public let exportedAt: Date
    public let schemaVersion: Int
    public let workouts: [WorkoutSnapshot]
    public let jumpTests: [JumpTestSnapshot]
    public let readinessSnapshots: [ReadinessSnapshotDTO]
    public let personalRecords: [PRDTO]

    public init(
        workouts: [WorkoutSnapshot],
        jumpTests: [JumpTestSnapshot],
        readinessSnapshots: [ReadinessSnapshotDTO],
        personalRecords: [PRDTO]
    ) {
        exportedAt = Date()
        schemaVersion = 1
        self.workouts = workouts
        self.jumpTests = jumpTests
        self.readinessSnapshots = readinessSnapshots
        self.personalRecords = personalRecords
    }
}

public struct ReadinessSnapshotDTO: Codable, Sendable {
    public let date: Date
    public let score: Int?
    public let tier: String
    public let hrv: Double?
    public let restingHR: Int?
    public let sleepDurationHours: Double?
    public let deepSleepHours: Double?
    public let wristTemperatureDelta: Double?
}

public struct PRDTO: Codable, Sendable {
    public let exerciseId: String
    public let kind: String
    public let value: Double
    public let achievedAt: Date
}

@available(iOS 17.0, watchOS 10.0, *)
public enum JSONExporter {
    public static func backup(in context: ModelContext) -> VBTBackup {
        let workouts: [WorkoutSnapshot] = WorkoutStore.all(in: context).map(WorkoutStore.snapshot(of:))

        let jumpDescriptor = FetchDescriptor<JumpTest>(sortBy: [SortDescriptor(\.performedAt, order: .reverse)])
        let jumps: [JumpTestSnapshot] = ((try? context.fetch(jumpDescriptor)) ?? []).map { j in
            JumpTestSnapshot(
                id: j.id,
                performedAt: j.performedAt,
                attempts: j.attempts,
                flightTimeSeconds: j.flightTimeSeconds,
                bestHeightCm: j.bestHeightCm,
                linkedWorkoutId: j.linkedWorkoutId
            )
        }

        let readinessDescriptor = FetchDescriptor<ReadinessSnapshot>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let readinessRows: [ReadinessSnapshotDTO] = ((try? context.fetch(readinessDescriptor)) ?? []).map { r in
            ReadinessSnapshotDTO(
                date: r.date,
                score: r.score,
                tier: r.tierRaw,
                hrv: r.hrv,
                restingHR: r.restingHR,
                sleepDurationHours: r.sleepDurationHours,
                deepSleepHours: r.deepSleepHours,
                wristTemperatureDelta: r.wristTemperatureDelta
            )
        }

        let prDescriptor = FetchDescriptor<PersonalRecord>(sortBy: [SortDescriptor(\.achievedAt, order: .reverse)])
        let prs: [PRDTO] = ((try? context.fetch(prDescriptor)) ?? []).map { p in
            PRDTO(
                exerciseId: p.exerciseId,
                kind: p.kindRaw,
                value: p.value,
                achievedAt: p.achievedAt
            )
        }

        return VBTBackup(
            workouts: workouts,
            jumpTests: jumps,
            readinessSnapshots: readinessRows,
            personalRecords: prs
        )
    }

    public static func writeFile(in context: ModelContext, to url: URL) throws {
        let backup = backup(in: context)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        try data.write(to: url)
    }
}
