// ReadinessSnapshot.swift
// VBTrainer · 2026-05
//
// Daily readiness snapshot — stored once per calendar day (start-of-day key).
// Score is computed by a separate ReadinessService (Proposal 7); model is
// passive storage.
//
// References:
//   - Citations.plews2013HRV (HRV in elite endurance)
//   - Citations.flattEsco2016HRV (smartphone HRV + training load)
//   - Citations.buchheit2014HR (HR-based monitoring)
//   - Citations.watson2017Sleep (sleep & athletic performance)

import Foundation
import SwiftData

@Model
public final class ReadinessSnapshot {
    @Attribute(.unique) public var id: UUID
    public var date: Date // start-of-day, unique per day

    // Sleep
    public var sleepDurationHours: Double?
    public var deepSleepHours: Double?
    public var remSleepHours: Double?

    // HRV
    public var hrv: Double? // SDNN in ms
    public var hrvBaseline: Double? // 7-day rolling

    // Resting HR
    public var restingHR: Int?
    public var restingHRBaseline: Double?

    /// Wrist temperature (Apple Watch Series 8+)
    public var wristTemperatureDelta: Double? // Celsius offset from baseline

    public var respiratoryRate: Double?

    // Computed score (nil if insufficient baseline)
    public var score: Int?
    public var tierRaw: String

    public init(
        id: UUID = UUID(),
        date: Date,
        sleepDurationHours: Double? = nil,
        deepSleepHours: Double? = nil,
        remSleepHours: Double? = nil,
        hrv: Double? = nil,
        hrvBaseline: Double? = nil,
        restingHR: Int? = nil,
        restingHRBaseline: Double? = nil,
        wristTemperatureDelta: Double? = nil,
        respiratoryRate: Double? = nil,
        score: Int? = nil,
        tier: ReadinessTier = .insufficient
    ) {
        self.id = id
        self.date = date
        self.sleepDurationHours = sleepDurationHours
        self.deepSleepHours = deepSleepHours
        self.remSleepHours = remSleepHours
        self.hrv = hrv
        self.hrvBaseline = hrvBaseline
        self.restingHR = restingHR
        self.restingHRBaseline = restingHRBaseline
        self.wristTemperatureDelta = wristTemperatureDelta
        self.respiratoryRate = respiratoryRate
        self.score = score
        tierRaw = tier.rawValue
    }

    public var tier: ReadinessTier {
        get { ReadinessTier(rawValue: tierRaw) ?? .insufficient }
        set { tierRaw = newValue.rawValue }
    }
}
