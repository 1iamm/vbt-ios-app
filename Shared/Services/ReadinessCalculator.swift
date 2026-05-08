// ReadinessCalculator.swift
// VBTrainer · 2026-05
//
// Pure-function readiness scoring. Inputs are pre-computed measurements
// (passed in by ReadinessRefresher); output is a Score + Tier and a
// breakdown of subscores.
//
// References:
//   - Citations.plews2013HRV (HRV deviation as readiness signal)
//   - Citations.flattEsco2016HRV
//   - Citations.buchheit2014HR
//   - Citations.watson2017Sleep

import Foundation

public struct ReadinessInput: Sendable, Equatable {
    public var hrv: Double?
    public var hrvBaselineMean: Double?
    public var hrvBaselineStd: Double?

    public var rhr: Int?
    public var rhrBaselineMean: Double?
    public var rhrBaselineStd: Double?

    public var sleepTotalHours: Double?
    public var sleepDeepHours: Double?

    public var wristTempDelta: Double?    // Celsius from baseline

    public init(
        hrv: Double? = nil,
        hrvBaselineMean: Double? = nil,
        hrvBaselineStd: Double? = nil,
        rhr: Int? = nil,
        rhrBaselineMean: Double? = nil,
        rhrBaselineStd: Double? = nil,
        sleepTotalHours: Double? = nil,
        sleepDeepHours: Double? = nil,
        wristTempDelta: Double? = nil
    ) {
        self.hrv = hrv
        self.hrvBaselineMean = hrvBaselineMean
        self.hrvBaselineStd = hrvBaselineStd
        self.rhr = rhr
        self.rhrBaselineMean = rhrBaselineMean
        self.rhrBaselineStd = rhrBaselineStd
        self.sleepTotalHours = sleepTotalHours
        self.sleepDeepHours = sleepDeepHours
        self.wristTempDelta = wristTempDelta
    }
}

public struct ReadinessOutput: Sendable, Equatable {
    public let score: Int?
    public let tier: ReadinessTier
    public let hrvSubscore: Int?
    public let rhrSubscore: Int?
    public let sleepSubscore: Int?
    public let tempSubscore: Int?
}

public enum ReadinessCalculator {

    /// Reference: Citations.plews2013HRV — HRV / readiness weighting.
    public static let weightHRV: Double   = 0.50
    public static let weightSleep: Double = 0.25
    public static let weightRHR: Double   = 0.20
    public static let weightTemp: Double  = 0.05

    public static func compute(input: ReadinessInput) -> ReadinessOutput {
        // Need at least HRV with baseline (or RHR with baseline) to score.
        let hasHRV = input.hrv != nil && input.hrvBaselineMean != nil
        let hasRHR = input.rhr != nil && input.rhrBaselineMean != nil

        guard hasHRV || hasRHR else {
            return ReadinessOutput(
                score: nil,
                tier: .insufficient,
                hrvSubscore: nil, rhrSubscore: nil, sleepSubscore: nil, tempSubscore: nil
            )
        }

        let hrvSub = hrvSubscore(input)
        let rhrSub = rhrSubscore(input)
        let sleepSub = sleepSubscore(input)
        let tempSub = tempSubscore(input)

        // Weighted average over available subscores
        var totalWeight: Double = 0
        var totalScore: Double = 0
        if let s = hrvSub   { totalScore += Double(s) * weightHRV;   totalWeight += weightHRV }
        if let s = sleepSub { totalScore += Double(s) * weightSleep; totalWeight += weightSleep }
        if let s = rhrSub   { totalScore += Double(s) * weightRHR;   totalWeight += weightRHR }
        if let s = tempSub  { totalScore += Double(s) * weightTemp;  totalWeight += weightTemp }

        guard totalWeight > 0 else {
            return ReadinessOutput(
                score: nil, tier: .insufficient,
                hrvSubscore: hrvSub, rhrSubscore: rhrSub, sleepSubscore: sleepSub, tempSubscore: tempSub
            )
        }

        let normalized = totalScore / totalWeight
        let score = Int(normalized.rounded())
        return ReadinessOutput(
            score: score,
            tier: tierFromScore(score),
            hrvSubscore: hrvSub,
            rhrSubscore: rhrSub,
            sleepSubscore: sleepSub,
            tempSubscore: tempSub
        )
    }

    public static func tierFromScore(_ score: Int) -> ReadinessTier {
        switch score {
        case 80...:   return .green
        case 60..<80: return .yellow
        default:      return .red
        }
    }

    // MARK: - Subscore helpers (each returns 0-100)

    private static func hrvSubscore(_ input: ReadinessInput) -> Int? {
        guard let hrv = input.hrv,
              let mean = input.hrvBaselineMean else { return nil }
        let std = input.hrvBaselineStd ?? max(1, mean * 0.1)
        let z = (hrv - mean) / std    // higher than baseline is better for HRV
        return scoreFromZ(z, higherIsBetter: true)
    }

    private static func rhrSubscore(_ input: ReadinessInput) -> Int? {
        guard let rhr = input.rhr,
              let mean = input.rhrBaselineMean else { return nil }
        let std = input.rhrBaselineStd ?? max(1, mean * 0.05)
        let z = (Double(rhr) - mean) / std    // lower rhr is better
        return scoreFromZ(z, higherIsBetter: false)
    }

    private static func sleepSubscore(_ input: ReadinessInput) -> Int? {
        guard let total = input.sleepTotalHours else { return nil }
        // Reference: Citations.watson2017Sleep — adults benefit from 7-9h.
        // Score = max at 7.5h, drops linearly outside [6, 9].
        let totalScore: Double
        switch total {
        case ..<5:    totalScore = 30
        case 5..<6:   totalScore = 50 + (total - 5) * 30
        case 6..<7.5: totalScore = 80 + (total - 6) * 13
        case 7.5...9: totalScore = 100 - (total - 7.5) * 5
        default:      totalScore = max(50, 80 - (total - 9) * 10)
        }

        // Bonus from deep sleep (max +10 if deep ≥ 1.5h)
        var bonus: Double = 0
        if let deep = input.sleepDeepHours {
            bonus = min(10, deep / 1.5 * 10)
        }

        return Int(min(100, max(0, totalScore + bonus)).rounded())
    }

    private static func tempSubscore(_ input: ReadinessInput) -> Int? {
        guard let delta = input.wristTempDelta else { return nil }
        // 0°C deviation = 100; ±0.5°C = 70; ±1°C = 30; outside that = lower
        let absDelta = abs(delta)
        switch absDelta {
        case ..<0.2: return 100
        case 0.2..<0.5: return 90
        case 0.5..<0.8: return 70
        case 0.8..<1.2: return 40
        default: return 20
        }
    }

    /// Maps a z-score to 0-100. Within ±1σ → 100, between ±1σ and ±2σ → linearly down to 30.
    private static func scoreFromZ(_ z: Double, higherIsBetter: Bool) -> Int {
        let effective = higherIsBetter ? z : -z
        switch effective {
        case 1...:           return 100
        case 0..<1:          return Int((90 + effective * 10).rounded())  // 90-100
        case -1..<0:         return Int((90 + effective * 30).rounded())  // 60-90
        case -2..<(-1):      return Int((30 + (effective + 2) * 30).rounded()) // 30-60
        default:             return 0
        }
    }
}
