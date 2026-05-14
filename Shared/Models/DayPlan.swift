// DayPlan.swift
// VBTrainer · 2026-05
//
// One scheduled training day. Replaces the @AppStorage JSON map with a real
// SwiftData entity so:
//   - history can join workouts ↔ scheduled days for "planned vs done" dots
//   - weekly planner can iterate / edit / delete entries
//   - EventKit identifiers persist for bidirectional iOS Calendar sync
//
// One DayPlan per (date, templateId) pair; date is normalized to startOfDay.

import Foundation
import SwiftData

@Model
public final class DayPlan {
    @Attribute(.unique) public var id: UUID
    public var date: Date // start-of-day in user's calendar
    public var templateId: UUID
    public var scheduledTimeMinutes: Int // minutes after midnight (0-1439)
    public var eventKitIdentifier: String? // EKEvent.eventIdentifier when synced
    public var completed: Bool // legacy boolean; kept in sync with statusRaw
    public var completedWorkoutId: UUID?
    public var createdAt: Date

    /// Lifecycle status — source of truth for Today banner / dot color /
    /// AI engine inputs. `completed` Bool is kept in sync for legacy readers.
    public var statusRaw: String = DayPlanStatus.scheduled.rawValue
    public var statusUpdatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        date: Date,
        templateId: UUID,
        scheduledTimeMinutes: Int = 7 * 60 + 30, // default 07:30
        eventKitIdentifier: String? = nil,
        completed: Bool = false,
        completedWorkoutId: UUID? = nil,
        createdAt: Date = Date(),
        status: DayPlanStatus = .scheduled
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.templateId = templateId
        self.scheduledTimeMinutes = scheduledTimeMinutes
        self.eventKitIdentifier = eventKitIdentifier
        self.completed = completed
        self.completedWorkoutId = completedWorkoutId
        self.createdAt = createdAt
        statusRaw = status.rawValue
        statusUpdatedAt = createdAt
    }

    public var status: DayPlanStatus {
        get { DayPlanStatus(rawValue: statusRaw) ?? .scheduled }
        set {
            statusRaw = newValue.rawValue
            statusUpdatedAt = Date()
            // Keep legacy `completed` Bool in sync.
            completed = (newValue == .completed)
        }
    }

    public var scheduledHHMM: String {
        let h = scheduledTimeMinutes / 60
        let m = scheduledTimeMinutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}
