// UserProfile.swift
// VBTrainer · 2026-05
//
// Singleton user profile, captured during onboarding.
// All fields needed by V1 algorithms (HRmax, body composition for jump
// analysis defaults) AND staged for V2 AI personalization.

import Foundation
import SwiftData

@Model
public final class UserProfile {
    @Attribute(.unique) public var id: UUID

    // Demographics
    public var age: Int
    public var sexRaw: String
    public var heightCm: Double
    public var weightKg: Double
    public var bodyTypeRaw: String
    public var trainingExperienceRaw: String
    public var trainingGoalRaw: String

    // Heart rate config (optional measured values)
    public var measuredHRMax: Int?
    public var restingHR: Int?

    // Preferences
    public var weightUnitRaw: String
    public var crownStep: Double
    public var defaultRestSeconds: Int
    public var vibrationEnabled: Bool
    public var cmjOnEachWorkout: Bool

    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        age: Int,
        sex: Sex,
        heightCm: Double,
        weightKg: Double,
        bodyType: BodyType = .standard,
        trainingExperience: TrainingExperience = .oneToThree,
        trainingGoal: TrainingGoal = .strength,
        measuredHRMax: Int? = nil,
        restingHR: Int? = nil,
        weightUnit: WeightUnit = .kg,
        crownStep: Double = 2.5,
        defaultRestSeconds: Int = 90,
        vibrationEnabled: Bool = true,
        cmjOnEachWorkout: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.age = age
        sexRaw = sex.rawValue
        self.heightCm = heightCm
        self.weightKg = weightKg
        bodyTypeRaw = bodyType.rawValue
        trainingExperienceRaw = trainingExperience.rawValue
        trainingGoalRaw = trainingGoal.rawValue
        self.measuredHRMax = measuredHRMax
        self.restingHR = restingHR
        weightUnitRaw = weightUnit.rawValue
        self.crownStep = crownStep
        self.defaultRestSeconds = defaultRestSeconds
        self.vibrationEnabled = vibrationEnabled
        self.cmjOnEachWorkout = cmjOnEachWorkout
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Typed accessors

    public var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .other }
        set { sexRaw = newValue.rawValue }
    }

    public var bodyType: BodyType {
        get { BodyType(rawValue: bodyTypeRaw) ?? .standard }
        set { bodyTypeRaw = newValue.rawValue }
    }

    public var trainingExperience: TrainingExperience {
        get { TrainingExperience(rawValue: trainingExperienceRaw) ?? .oneToThree }
        set { trainingExperienceRaw = newValue.rawValue }
    }

    public var trainingGoal: TrainingGoal {
        get { TrainingGoal(rawValue: trainingGoalRaw) ?? .strength }
        set { trainingGoalRaw = newValue.rawValue }
    }

    public var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    // MARK: - Derived

    /// HRmax — measured if available, else Tanaka formula.
    /// Reference: Citations.tanaka2001HRMax (HRmax = 208 - 0.7×age, more
    /// accurate than the legacy 220-age across age groups).
    public var hrMax: Int {
        if let measured = measuredHRMax { return measured }
        return Int((208.0 - 0.7 * Double(age)).rounded())
    }
}
