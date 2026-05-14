// WorkoutSnapshot.swift
// VBTrainer · 2026-05
//
// Plain value type emitted by ActiveWorkoutSession.complete(). The storage
// layer (Proposal 4) consumes this to persist into SwiftData and ship to
// the iPhone via WatchConnectivity.

import Foundation

public struct WorkoutSnapshot: Sendable, Codable, Equatable {
    public let id: UUID
    public let exerciseId: String
    public let startedAt: Date
    public let endedAt: Date
    public var sets: [SetSnapshot]
    public var heartRateSamples: [HeartRateSample]
    public var rpe: Int?
    public var linkedTemplateId: UUID?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        exerciseId: String,
        startedAt: Date,
        endedAt: Date,
        sets: [SetSnapshot] = [],
        heartRateSamples: [HeartRateSample] = [],
        rpe: Int? = nil,
        linkedTemplateId: UUID? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.sets = sets
        self.heartRateSamples = heartRateSamples
        self.rpe = rpe
        self.linkedTemplateId = linkedTemplateId
        self.notes = notes
    }

    public var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps.count }
    }
}

public struct SetSnapshot: Sendable, Codable, Equatable {
    public let id: UUID
    public let index: Int
    public let weightKg: Double
    public let velocityVariantRaw: String
    public let targetVelocityMin: Double?
    public let targetVelocityMax: Double?
    public let vlCeiling: Double?
    public let sideRaw: String
    public let restAfterSeconds: Int
    public var reps: [RepSnapshot]

    public init(
        id: UUID = UUID(),
        index: Int,
        weightKg: Double,
        velocityVariant: VelocityVariant,
        targetRange: ClosedRange<Double>?,
        vlCeiling: Double?,
        side: Side,
        restAfterSeconds: Int,
        reps: [RepSnapshot] = []
    ) {
        self.id = id
        self.index = index
        self.weightKg = weightKg
        velocityVariantRaw = velocityVariant.rawValue
        targetVelocityMin = targetRange?.lowerBound
        targetVelocityMax = targetRange?.upperBound
        self.vlCeiling = vlCeiling
        sideRaw = side.rawValue
        self.restAfterSeconds = restAfterSeconds
        self.reps = reps
    }

    public var velocityVariant: VelocityVariant {
        VelocityVariant(rawValue: velocityVariantRaw) ?? .mv
    }

    public var targetRange: ClosedRange<Double>? {
        guard let lo = targetVelocityMin, let hi = targetVelocityMax, lo <= hi else { return nil }
        return lo...hi
    }

    public var side: Side {
        Side(rawValue: sideRaw) ?? .both
    }
}

public struct RepSnapshot: Sendable, Codable, Equatable {
    public let id: UUID
    public let index: Int
    public let meanVelocity: Double
    public let peakVelocity: Double
    public let meanPropulsiveVelocity: Double
    public let timestamp: Date
    public let metStatusRaw: String

    public init(
        id: UUID = UUID(),
        index: Int,
        meanVelocity: Double,
        peakVelocity: Double,
        meanPropulsiveVelocity: Double,
        timestamp: Date,
        metStatus: MetStatus
    ) {
        self.id = id
        self.index = index
        self.meanVelocity = meanVelocity
        self.peakVelocity = peakVelocity
        self.meanPropulsiveVelocity = meanPropulsiveVelocity
        self.timestamp = timestamp
        metStatusRaw = metStatus.rawValue
    }

    public var metStatus: MetStatus {
        MetStatus(rawValue: metStatusRaw) ?? .met
    }
}

public struct HeartRateSample: Sendable, Codable, Equatable {
    public let timestamp: Date
    public let bpm: Int

    public init(timestamp: Date, bpm: Int) {
        self.timestamp = timestamp
        self.bpm = bpm
    }
}
