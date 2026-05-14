// ReadinessRefresher.swift
// VBTrainer · 2026-05
//
// Pulls fresh data from HealthKitService, computes via ReadinessCalculator,
// and persists via ReadinessStore.

import Foundation
import SwiftData

#if canImport(HealthKit)
    import HealthKit
#endif

@available(iOS 17.0, watchOS 10.0, *)
public enum ReadinessRefresher {
    public static func refresh(in container: ModelContainer) async {
        #if canImport(HealthKit)
            let svc = HealthKitService.shared

            async let sleepTuple = svc.latestSleep()
            async let hrvVal = svc.latestHRV()
            async let rhrVal = svc.latestRestingHR()
            async let tempVal = svc.latestWristTemperature()
            async let respRate = svc.latestRespiratoryRate()

            let sleep = await sleepTuple
            let hrv = await hrvVal
            let rhr = await rhrVal
            let temp = await tempVal
            let resp = await respRate

            // Baseline: 7-day HRV / RHR mean & std
            let hrvDaily = await svc.recentDailyValues(
                identifier: .heartRateVariabilitySDNN,
                unit: HKUnit.secondUnit(with: .milli),
                days: 7
            )
            let rhrDaily = await svc.recentDailyValues(
                identifier: .restingHeartRate,
                unit: HKUnit.count().unitDivided(by: .minute()),
                days: 7
            )

            let hrvMean = mean(hrvDaily)
            let hrvStd = std(hrvDaily, mean: hrvMean ?? 0)
            let rhrMean = mean(rhrDaily)
            let rhrStd = std(rhrDaily, mean: rhrMean ?? 0)

            // Wrist temperature delta — V1 uses HealthKit's already-computed
            // sleeping wrist temperature (which is itself a delta from baseline).
            let tempDelta = temp.map { $0 - 36.6 } // rough body baseline; refine later

            let input = ReadinessInput(
                hrv: hrv, hrvBaselineMean: hrvMean, hrvBaselineStd: hrvStd,
                rhr: rhr, rhrBaselineMean: rhrMean, rhrBaselineStd: rhrStd,
                sleepTotalHours: sleep.totalHours,
                sleepDeepHours: sleep.deepHours,
                wristTempDelta: tempDelta
            )

            let output = ReadinessCalculator.compute(input: input)

            let snapshot = ReadinessSnapshot(
                date: Date(),
                sleepDurationHours: sleep.totalHours,
                deepSleepHours: sleep.deepHours,
                remSleepHours: sleep.remHours,
                hrv: hrv,
                hrvBaseline: hrvMean,
                restingHR: rhr,
                restingHRBaseline: rhrMean,
                wristTemperatureDelta: tempDelta,
                respiratoryRate: resp,
                score: output.score,
                tier: output.tier
            )

            await MainActor.run {
                let context = ModelContext(container)
                ReadinessStore.upsert(snapshot, in: context)
            }
        #endif
    }

    private static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func std(_ values: [Double], mean: Double) -> Double? {
        guard values.count > 1 else { return nil }
        let sumSq = values.reduce(0) { $0 + pow($1 - mean, 2) }
        return (sumSq / Double(values.count - 1)).squareRoot()
    }
}
