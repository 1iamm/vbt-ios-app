// HealthKitService.swift
// VBTrainer · 2026-05
//
// Async wrapper around HealthKit reads. Returns nil/empty when data is
// unavailable rather than throwing.
//
// References:
//   - Citations.plews2013HRV (HRV monitoring)
//   - Citations.flattEsco2016HRV
//   - Citations.watson2017Sleep

import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

@available(iOS 17.0, watchOS 10.0, *)
public actor HealthKitService {

    public static let shared = HealthKitService()

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    #endif

    public init() {}

    // MARK: - Sleep

    public func latestSleep(within hours: Double = 18) async -> (totalHours: Double?, deepHours: Double?, remHours: Double?) {
        #if canImport(HealthKit)
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (nil, nil, nil)
        }
        let end = Date()
        let start = end.addingTimeInterval(-hours * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        do {
            let samples = try await fetchSamples(type: type, predicate: predicate)
            return aggregateSleep(samples: samples as? [HKCategorySample] ?? [])
        } catch {
            return (nil, nil, nil)
        }
        #else
        return (nil, nil, nil)
        #endif
    }

    // MARK: - HRV (SDNN ms)

    public func latestHRV() async -> Double? {
        #if canImport(HealthKit)
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
        let unit = HKUnit.secondUnit(with: .milli)
        return await fetchLatestQuantity(type: type, unit: unit)
        #else
        return nil
        #endif
    }

    // MARK: - Resting HR

    public func latestRestingHR() async -> Int? {
        #if canImport(HealthKit)
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        if let v = await fetchLatestQuantity(type: type, unit: unit) {
            return Int(v.rounded())
        }
        return nil
        #else
        return nil
        #endif
    }

    // MARK: - Wrist temperature

    public func latestWristTemperature() async -> Double? {
        #if canImport(HealthKit)
        guard #available(iOS 17.0, *),
              let type = HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature)
        else { return nil }
        let unit = HKUnit.degreeCelsius()
        return await fetchLatestQuantity(type: type, unit: unit)
        #else
        return nil
        #endif
    }

    // MARK: - Respiratory rate

    public func latestRespiratoryRate() async -> Double? {
        #if canImport(HealthKit)
        guard let type = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await fetchLatestQuantity(type: type, unit: unit)
        #else
        return nil
        #endif
    }

    // MARK: - Generic recent samples (for baseline)

    #if canImport(HealthKit)
    public func recentDailyValues(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        days: Int
    ) async -> [Double] {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -days, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        do {
            let samples = try await fetchSamples(type: type, predicate: predicate)
            let qs = samples.compactMap { $0 as? HKQuantitySample }
            // Group by calendar day, take daily mean
            let dict = Dictionary(grouping: qs) { cal.startOfDay(for: $0.startDate) }
            return dict.values.map { dayItems in
                let vs = dayItems.map { $0.quantity.doubleValue(for: unit) }
                return vs.reduce(0, +) / Double(vs.count)
            }.sorted()
        } catch {
            return []
        }
    }
    #endif

    // MARK: - Helpers

    #if canImport(HealthKit)
    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-7 * 86400),
            end: Date(),
            options: .strictStartDate
        )
        do {
            let samples = try await fetchSamples(type: type, predicate: predicate, limit: 1, sortDescending: true)
            guard let sample = samples.first as? HKQuantitySample else { return nil }
            return sample.quantity.doubleValue(for: unit)
        } catch {
            return nil
        }
    }

    private func fetchSamples(
        type: HKObjectType,
        predicate: NSPredicate,
        limit: Int = HKObjectQueryNoLimit,
        sortDescending: Bool = true
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { cont in
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: !sortDescending
            )
            let q = HKSampleQuery(
                sampleType: type as! HKSampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: samples ?? [])
            }
            store.execute(q)
        }
    }

    private func aggregateSleep(samples: [HKCategorySample]) -> (totalHours: Double?, deepHours: Double?, remHours: Double?) {
        guard !samples.isEmpty else { return (nil, nil, nil) }
        var total: Double = 0
        var deep: Double = 0
        var rem: Double = 0
        for s in samples {
            let dur = s.endDate.timeIntervalSince(s.startDate)
            switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
            case .asleepCore, .asleepUnspecified:
                total += dur
            case .asleepDeep:
                total += dur
                deep += dur
            case .asleepREM:
                total += dur
                rem += dur
            default:
                break
            }
        }
        return (total / 3600, deep / 3600, rem / 3600)
    }
    #endif
}
