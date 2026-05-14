// Enums.swift
// VBTrainer · 2026-05
//
// All enum types used across models. Defined as String-backed to make them
// SwiftData-friendly and JSON-exportable (CSV/JSON export in later proposals).
//
// Adding a case requires a SwiftData schema migration; design accordingly.

import Foundation

public enum Sex: String, Codable, CaseIterable, Sendable {
    case male, female, other
}

/// V2.x: how a workout was recorded.
/// - `watch`: Watch IMU drove rep detection + velocity (the original mode)
/// - `iPhone`: iPhone-only manual logging (no IMU; user inputs reps/weight)
/// - `hybrid`: mixed (reserved for V2 fallback)
public enum WorkoutSource: String, Codable, CaseIterable, Sendable {
    case watch
    case iPhone = "iphone"
    case hybrid
}

/// V2.x: per-set capture mode. Empty `reps` array signals manual mode where
/// only total rep count + weight are known (no per-rep velocity).
public enum SetInputMode: String, Codable, CaseIterable, Sendable {
    case watchIMU = "watch_imu"
    case iPhoneManual = "iphone_manual"
}

/// V2.x: user-controlled training mode override stored in UserDefaults.
/// `auto` follows `WCSession.isPaired`; the other two force the path.
public enum TrainingModePreference: String, Codable, CaseIterable, Sendable {
    case auto
    case forceWatch = "force_watch"
    case forceIPhone = "force_iphone"
}

public enum BodyType: String, Codable, CaseIterable, Sendable {
    case lean // 瘦
    case standard // 标准
    case stocky // 偏壮
    case muscular // 健美
    case powerlifter // 力量型
}

public enum TrainingExperience: String, Codable, CaseIterable, Sendable {
    case lessThan1Year = "<1y"
    case oneToThree = "1-3y"
    case threeToFive = "3-5y"
    case moreThan5Years = ">5y"
}

public enum TrainingGoal: String, Codable, CaseIterable, Sendable {
    case power // 爆发
    case strength // 力量
    case muscle // 增肌
    case fatLoss // 减脂
    case general // 综合
}

public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kg, lb
}

public enum Side: String, Codable, CaseIterable, Sendable {
    case both, left, right
}

/// Velocity variant used to assess a rep.
/// Reference: Sánchez-Medina et al. (2010) — exercises with significant
/// braking phase use MPV; simple concentric-dominant lifts use MV;
/// explosive movements (CMJ, snatch) use PV.
public enum VelocityVariant: String, Codable, CaseIterable, Sendable {
    case mv // mean velocity
    case mpv // mean propulsive velocity
    case pv // peak velocity
}

/// Per-rep target met status (drives haptic feedback).
public enum MetStatus: String, Codable, CaseIterable, Sendable {
    case excellent // ≥ upper bound
    case met // within target band
    case borderline // slightly below lower bound
    case failed // well below lower bound
}

public enum ReadinessTier: String, Codable, CaseIterable, Sendable {
    case green // ≥80
    case yellow // 60-79
    case red // <60
    case insufficient // not enough baseline data yet
}

public enum PRKind: String, Codable, CaseIterable, Sendable {
    case maxWeight
    case e1RM
    case maxVolume
    case maxSingleRepVelocity
    case maxCMJ
}

public enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case barbell, dumbbell, bodyweight, machine, jump
}

public enum CitationTopic: String, Codable, CaseIterable, Sendable {
    case appleWatchValidation
    case repDetection
    case velocityIntegration
    case velocityLoss
    case v1RM
    case lvpAndE1RM
    case velocityVariant
    case heartRate
    case hrvReadiness
    case sleep
    case cmjNeuromuscular
}

/// Lifecycle status of a scheduled DayPlan. Drives Today banner copy / CTA,
/// dot color in history calendar, and downstream readers (AI engine, EventKit
/// reverse sync, stats).
public enum DayPlanStatus: String, Codable, CaseIterable, Sendable {
    case scheduled // future or today, not yet started
    case inProgress // Watch session running for this plan
    case completed // workout finished + persisted
    case skipped // user explicitly cancelled (or calendar event deleted)
    case missed // past, never started — auto-marked at midnight rollover
}
