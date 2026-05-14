// HeartRateManager.swift
// VBTrainer · watchOS · 2026-05
//
// HealthKit anchored-object query subscription for live heart-rate samples
// during a workout. Emits Int bpm values via AsyncStream.

import Foundation

#if canImport(HealthKit)
    import HealthKit
#endif

@available(watchOS 10.0, *)
public actor HeartRateManager {
    public enum AuthState {
        case notDetermined
        case authorized
        case denied
    }

    public private(set) var authState: AuthState = .notDetermined

    public var stream: AsyncStream<Int> {
        _stream
    }

    #if canImport(HealthKit)
        private let healthStore = HKHealthStore()
        private var query: HKAnchoredObjectQuery?
        private var anchor: HKQueryAnchor?
    #endif

    private let _stream: AsyncStream<Int>
    private let continuation: AsyncStream<Int>.Continuation

    public init() {
        var c: AsyncStream<Int>.Continuation!
        _stream = AsyncStream { c = $0 }
        continuation = c
    }

    public func requestAuthorizationIfNeeded() async {
        #if canImport(HealthKit)
            guard authState == .notDetermined else { return }
            let hr = HKQuantityType(.heartRate)
            do {
                try await healthStore.requestAuthorization(toShare: [], read: [hr])
                authState = .authorized
            } catch {
                authState = .denied
            }
        #else
            authState = .denied
        #endif
    }

    public func start() async {
        await requestAuthorizationIfNeeded()
        #if canImport(HealthKit)
            guard authState == .authorized else { return }
            let hr = HKQuantityType(.heartRate)
            let bpmUnit = HKUnit.count().unitDivided(by: .minute())

            let q = HKAnchoredObjectQuery(
                type: hr,
                predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate),
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { [weak self] _, samples, _, newAnchor, _ in
                guard let self else { return }
                Task { await self.handleSamples(samples, bpmUnit: bpmUnit, anchor: newAnchor) }
            }
            q.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
                guard let self else { return }
                Task { await self.handleSamples(samples, bpmUnit: bpmUnit, anchor: newAnchor) }
            }
            healthStore.execute(q)
            query = q
        #endif
    }

    public func stop() {
        #if canImport(HealthKit)
            if let q = query { healthStore.stop(q) }
            query = nil
        #endif
        continuation.finish()
    }

    #if canImport(HealthKit)
        private func handleSamples(
            _ samples: [HKSample]?,
            bpmUnit: HKUnit,
            anchor: HKQueryAnchor?
        ) {
            if let anchor { self.anchor = anchor }
            guard let qs = samples as? [HKQuantitySample] else { return }
            for s in qs {
                let bpm = Int(s.quantity.doubleValue(for: bpmUnit).rounded())
                continuation.yield(bpm)
            }
        }
    #endif
}
