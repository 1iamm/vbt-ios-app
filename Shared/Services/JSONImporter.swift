// JSONImporter.swift
// VBTrainer · 2026-05
//
// Counterpart to JSONExporter — reads a `VBTBackup` JSON blob produced
// by a previous Export and merges its records into the user's current
// SwiftData container. Idempotent: re-importing the same backup is a
// no-op (each record is keyed by its `id`).
//
// Addresses Round 1 review PM-F6: M9 (本地备份) shipped Export but not
// Restore. Without Restore, V1 has no recovery path for "I reinstalled
// the app" — every workout history is gone.
//
// Out of scope (deferred):
//   - Templates: not in `VBTBackup` yet (Exporter doesn't include them)
//   - UserProfile: same
//   - DayPlan: same

import Foundation
import SwiftData

public enum JSONImporter {
    public struct Result: Sendable, Equatable {
        public let workoutsInserted: Int
        public let workoutsSkipped: Int // already-present (idempotent re-import)
        public let jumpTestsInserted: Int
        public let jumpTestsSkipped: Int
        public let readinessInserted: Int
        public let personalRecordsInserted: Int
    }

    public enum ImportError: Error {
        case malformedJSON(Error)
        case schemaVersionMismatch(Int)
        case persistenceFailure(Error)
    }

    /// Decode `data` as VBTBackup, merge each section into `context`,
    /// and `save()` once at the end. Returns counts of what was added
    /// vs skipped (already in store).
    @discardableResult
    public static func restore(
        from data: Data,
        in context: ModelContext
    ) throws -> Result {
        let backup: VBTBackup
        do {
            backup = try JSONDecoder.vbtDateAware.decode(VBTBackup.self, from: data)
        } catch {
            throw ImportError.malformedJSON(error)
        }
        // Only schema v1 supported for now. Future versions will need
        // migration paths; this guard prevents silently mis-decoding.
        guard backup.schemaVersion == 1 else {
            throw ImportError.schemaVersionMismatch(backup.schemaVersion)
        }

        var workoutsInserted = 0
        var workoutsSkipped = 0
        for snap in backup.workouts {
            let id = snap.id
            let existing = (try? context.fetch(
                FetchDescriptor<Workout>(predicate: #Predicate<Workout> { $0.id == id })
            ).first) != nil
            if existing {
                workoutsSkipped += 1
                continue
            }
            _ = try WorkoutStore.save(snap, in: context)
            workoutsInserted += 1
        }

        var jumpTestsInserted = 0
        var jumpTestsSkipped = 0
        for snap in backup.jumpTests {
            let id = snap.id
            let already = (try? context.fetch(
                FetchDescriptor<JumpTest>(predicate: #Predicate<JumpTest> { $0.id == id })
            ).first) != nil
            if already {
                jumpTestsSkipped += 1
                continue
            }
            // JumpTestStore.save takes a JumpTest model + ModelContext; we
            // need to materialize one from the snapshot first.
            let jt = JumpTest(
                id: snap.id,
                performedAt: snap.performedAt,
                attempts: snap.attempts,
                flightTimeSeconds: snap.flightTimeSeconds,
                linkedWorkoutId: snap.linkedWorkoutId
            )
            context.insert(jt)
            jumpTestsInserted += 1
        }

        var readinessInserted = 0
        for dto in backup.readinessSnapshots {
            let target = dto.date
            let already = (try? context.fetch(
                FetchDescriptor<ReadinessSnapshot>(predicate: #Predicate<ReadinessSnapshot> { $0.date == target })
            ).first) != nil
            if already { continue }
            let snap = ReadinessSnapshot(
                date: dto.date,
                sleepDurationHours: dto.sleepDurationHours,
                deepSleepHours: dto.deepSleepHours,
                hrv: dto.hrv,
                restingHR: dto.restingHR,
                wristTemperatureDelta: dto.wristTemperatureDelta,
                score: dto.score,
                tier: ReadinessTier(rawValue: dto.tier) ?? .insufficient
            )
            context.insert(snap)
            readinessInserted += 1
        }

        // PR de-dup by (exerciseId, kind, value, achievedAt) tuple. Backup
        // doesn't carry the PR's UUID (PersonalRecord uses generated IDs).
        // Round 3 Reliability C2: previously this loop unconditionally
        // inserted; re-importing the same backup doubled PR counts and
        // skewed AIRecommendationEngine's "PR cadence" rule. Now we skip
        // any row whose 4-tuple already exists.
        var personalRecordsInserted = 0
        var personalRecordsSkipped = 0
        for dto in backup.personalRecords {
            let kind = PRKind(rawValue: dto.kind) ?? .maxWeight
            let exId = dto.exerciseId
            let kindRaw = kind.rawValue
            let val = dto.value
            let at = dto.achievedAt
            let existsDescriptor = FetchDescriptor<PersonalRecord>(
                predicate: #Predicate<PersonalRecord> {
                    $0.exerciseId == exId
                        && $0.kindRaw == kindRaw
                        && $0.value == val
                        && $0.achievedAt == at
                }
            )
            if (try? context.fetch(existsDescriptor))?.isEmpty == false {
                personalRecordsSkipped += 1
                continue
            }
            let pr = PersonalRecord(
                exerciseId: dto.exerciseId,
                kind: kind,
                value: dto.value,
                achievedAt: dto.achievedAt
            )
            context.insert(pr)
            personalRecordsInserted += 1
        }

        do {
            try context.save()
        } catch {
            throw ImportError.persistenceFailure(error)
        }

        return Result(
            workoutsInserted: workoutsInserted,
            workoutsSkipped: workoutsSkipped,
            jumpTestsInserted: jumpTestsInserted,
            jumpTestsSkipped: jumpTestsSkipped,
            readinessInserted: readinessInserted,
            personalRecordsInserted: personalRecordsInserted
        )
    }
}

// MARK: - Shared decoder

private extension JSONDecoder {
    static let vbtDateAware: JSONDecoder = {
        let d = JSONDecoder()
        // VBTBackup uses Swift's default Date encoding (timeIntervalSinceReferenceDate
        // as a Double). Match the implicit Encoder.
        d.dateDecodingStrategy = .deferredToDate
        return d
    }()
}
