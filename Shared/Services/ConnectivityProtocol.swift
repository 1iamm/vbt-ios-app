// ConnectivityProtocol.swift
// VBTrainer · 2026-05
//
// Shared message envelope for WatchConnectivity. Both sides import this
// type and encode/decode via JSON.

import Foundation

public enum ConnectivityKind: String, Codable, Sendable {
    case workoutSnapshot
    case jumpTest
    case template          // Proposal 9 fills in
    case readiness         // Proposal 7 may push readiness from iPhone to Watch
}

public struct JumpTestSnapshot: Codable, Sendable, Equatable {
    public let id: UUID
    public let performedAt: Date
    public let attempts: [Double]
    public let flightTimeSeconds: [Double]
    public let bestHeightCm: Double
    public let linkedWorkoutId: UUID?

    public init(
        id: UUID = UUID(),
        performedAt: Date = Date(),
        attempts: [Double],
        flightTimeSeconds: [Double] = [],
        bestHeightCm: Double? = nil,
        linkedWorkoutId: UUID? = nil
    ) {
        self.id = id
        self.performedAt = performedAt
        self.attempts = attempts
        self.flightTimeSeconds = flightTimeSeconds
        self.bestHeightCm = bestHeightCm ?? (attempts.max() ?? 0)
        self.linkedWorkoutId = linkedWorkoutId
    }
}

public struct TemplateItemSnapshot: Codable, Sendable, Equatable {
    public let id: UUID
    public let index: Int
    public let exerciseId: String
    public let targetSets: Int
    public let targetReps: Int
    public let targetWeightKg: Double?
    public let targetVelocityMin: Double?
    public let targetVelocityMax: Double?
    public let vlCeiling: Double?
    public let restSeconds: Int
    public let sideRaw: String

    public init(
        id: UUID = UUID(),
        index: Int,
        exerciseId: String,
        targetSets: Int,
        targetReps: Int,
        targetWeightKg: Double?,
        targetVelocityMin: Double?,
        targetVelocityMax: Double?,
        vlCeiling: Double?,
        restSeconds: Int,
        sideRaw: String
    ) {
        self.id = id
        self.index = index
        self.exerciseId = exerciseId
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.targetVelocityMin = targetVelocityMin
        self.targetVelocityMax = targetVelocityMax
        self.vlCeiling = vlCeiling
        self.restSeconds = restSeconds
        self.sideRaw = sideRaw
    }
}

public struct TemplateSnapshot: Codable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let scheduledDate: Date    // start-of-day
    public let items: [TemplateItemSnapshot]

    public init(id: UUID = UUID(), name: String, scheduledDate: Date, items: [TemplateItemSnapshot]) {
        self.id = id
        self.name = name
        self.scheduledDate = scheduledDate
        self.items = items
    }
}

public enum ConnectivityMessage: Codable, Sendable, Equatable {
    case workoutSnapshot(WorkoutSnapshot)
    case jumpTest(JumpTestSnapshot)
    case template(TemplateSnapshot)

    public var kind: ConnectivityKind {
        switch self {
        case .workoutSnapshot: return .workoutSnapshot
        case .jumpTest:        return .jumpTest
        case .template:        return .template
        }
    }
}

public extension Notification.Name {
    static let vbtWorkoutImported = Notification.Name("vbt.workoutImported")
    static let vbtJumpTestImported = Notification.Name("vbt.jumpTestImported")
}

public enum ConnectivityCodec {
    public static let userInfoKindKey = "vbt.kind"
    public static let userInfoPayloadKey = "vbt.payload"

    public static func encode(_ message: ConnectivityMessage) throws -> [String: Any] {
        let data = try JSONEncoder().encode(message)
        return [
            userInfoKindKey: message.kind.rawValue,
            userInfoPayloadKey: data,
        ]
    }

    public static func decode(_ userInfo: [String: Any]) throws -> ConnectivityMessage? {
        guard
            let _ = userInfo[userInfoKindKey] as? String,
            let data = userInfo[userInfoPayloadKey] as? Data
        else { return nil }
        return try JSONDecoder().decode(ConnectivityMessage.self, from: data)
    }
}
