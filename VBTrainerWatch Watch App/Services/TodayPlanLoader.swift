// TodayPlanLoader.swift
// VBTrainer · watchOS · 2026-05
//
// Loads / persists today's plan in @AppStorage. Driven by inbound
// connectivity messages on the Watch.

import Foundation
import SwiftUI

@MainActor
public final class TodayPlanStore: ObservableObject {
    public static let shared = TodayPlanStore()

    @Published public private(set) var todayPlan: TemplateSnapshot?

    private let key = "vbt.todayPlan"

    public init() {
        load()
    }

    public func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(TemplateSnapshot.self, from: data) else
        {
            todayPlan = nil
            return
        }
        // Only consider it "today's" plan if its scheduledDate matches today.
        let isToday = Calendar.current.isDate(snap.scheduledDate, inSameDayAs: Date())
        todayPlan = isToday ? snap : nil
    }

    public func store(_ snap: TemplateSnapshot) {
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: key)
        }
        let isToday = Calendar.current.isDate(snap.scheduledDate, inSameDayAs: Date())
        if isToday {
            todayPlan = snap
        }
    }

    public func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        todayPlan = nil
    }
}
