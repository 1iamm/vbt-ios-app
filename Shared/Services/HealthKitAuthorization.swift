// HealthKitAuthorization.swift
// VBTrainer · 2026-05
//
// One-shot HealthKit authorization request invoked at app launch.
// Without this, HKWorkoutSession creation fails on first run, which silently
// breaks 100Hz IMU capture (CoreMotion is throttled outside an active session).

import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

@available(iOS 17.0, watchOS 10.0, *)
public enum HealthKitAuthorization {

    public enum AuthError: Error {
        case healthDataUnavailable
    }

    public static func requestWorkoutAuthorization() async throws {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AuthError.healthDataUnavailable
        }
        let store = HKHealthStore()

        var share: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            share.insert(energy)
        }

        var read: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { read.insert(hr) }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { read.insert(energy) }

        try await store.requestAuthorization(toShare: share, read: read)
        #endif
    }
}
