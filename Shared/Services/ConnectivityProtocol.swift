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
    case preferences       // iPhone Profile toggles → Watch (e.g. enableRepHaptic)
    case startWorkout      // V2: iPhone activates a synced template on the Watch
}

public struct WatchPreferencesSnapshot: Codable, Sendable, Equatable {
    public var enableRepHaptic: Bool

    public init(enableRepHaptic: Bool) {
        self.enableRepHaptic = enableRepHaptic
    }
}

/// V2 activation payload. Sent right after a `.template` push so the Watch can
/// pop to root and jump straight to the synced plan view instead of waiting
/// for the user to manually open the app.
public struct StartWorkoutSnapshot: Codable, Sendable, Equatable {
    public let templateId: UUID
    public let startItemIndex: Int

    public init(templateId: UUID, startItemIndex: Int = 0) {
        self.templateId = templateId
        self.startItemIndex = startItemIndex
    }
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

public struct TemplateSetSpecSnapshot: Codable, Sendable, Equatable {
    public let id: UUID
    public let index: Int
    public let kindRaw: String      // "warmUp" | "work"
    public let weightKg: Double
    public let reps: Int
    public let restSeconds: Int

    public init(
        id: UUID = UUID(),
        index: Int,
        kindRaw: String,
        weightKg: Double,
        reps: Int,
        restSeconds: Int
    ) {
        self.id = id
        self.index = index
        self.kindRaw = kindRaw
        self.weightKg = weightKg
        self.reps = reps
        self.restSeconds = restSeconds
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
    /// Per-set specs. When non-empty the Watch drives each set with the
    /// matching spec's weight/reps/rest. When empty (legacy templates),
    /// fall back to the targetSets × targetReps @ targetWeightKg pattern.
    public var setSpecs: [TemplateSetSpecSnapshot] = []

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
        sideRaw: String,
        setSpecs: [TemplateSetSpecSnapshot] = []
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
        self.setSpecs = setSpecs
    }

    /// Effective work-set count for UI summaries.
    public var effectiveWorkSetCount: Int {
        if setSpecs.isEmpty { return targetSets }
        return setSpecs.filter { $0.kindRaw == "work" }.count
    }

    /// Returns the parameters the Watch should use for `setIndex` (1-based).
    /// When per-set specs exist, picks them in order; falls back to legacy.
    public func paramsForSet(_ setIndex: Int) -> (weightKg: Double, reps: Int, restSeconds: Int, isWarmUp: Bool) {
        if !setSpecs.isEmpty {
            let ordered = setSpecs.sorted { $0.index < $1.index }
            if setIndex >= 1, setIndex <= ordered.count {
                let s = ordered[setIndex - 1]
                return (s.weightKg, s.reps, s.restSeconds, s.kindRaw == "warmUp")
            }
        }
        return (targetWeightKg ?? 0, targetReps, restSeconds, false)
    }

    public var totalSetCount: Int {
        setSpecs.isEmpty ? targetSets : setSpecs.count
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
    case preferences(WatchPreferencesSnapshot)
    case startWorkout(StartWorkoutSnapshot)

    public var kind: ConnectivityKind {
        switch self {
        case .workoutSnapshot: return .workoutSnapshot
        case .jumpTest:        return .jumpTest
        case .template:        return .template
        case .preferences:     return .preferences
        case .startWorkout:    return .startWorkout
        }
    }
}

public extension Notification.Name {
    static let vbtWorkoutImported = Notification.Name("vbt.workoutImported")
    static let vbtJumpTestImported = Notification.Name("vbt.jumpTestImported")
    /// Watch-side: posted by `WatchActivationCenter` when the iPhone sends a
    /// `.startWorkout` message. Handled by `WatchRootView` to pop to root and
    /// jump to the synced plan view.
    static let vbtWatchActivated = Notification.Name("vbt.watchActivated")
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
