// EventKitService.swift
// VBTrainer · 2026-05
//
// Thin wrapper around EventKit for syncing DayPlan ↔ iPhone Calendar.
// V1 implementation:
//   - request write-only access
//   - create / update / delete events keyed by DayPlan.eventKitIdentifier
//   - choose target calendar by name (default: "训练" — created on first sync)
//
// Bidirectional read-back (calendar edits → DayPlan) is V1.5+ work; we expose
// a hook here for future polling but don't run it.

import Foundation

#if canImport(EventKit) && os(iOS)
import EventKit
#endif

@available(iOS 17.0, *)
public final class EventKitService {

    public static let shared = EventKitService()

    public enum SyncError: Error {
        case accessDenied
        case calendarUnavailable
        case eventNotFound
    }

    public static let calendarName = "训练"

    #if canImport(EventKit) && os(iOS)
    private let store = EKEventStore()
    #endif

    public init() {}

    // MARK: - Auth

    /// Returns true if access was granted (write-only is enough on iOS 17+).
    @discardableResult
    public func requestWriteAccess() async -> Bool {
        #if canImport(EventKit) && os(iOS)
        do {
            if #available(iOS 17.0, *) {
                return try await store.requestWriteOnlyAccessToEvents()
            } else {
                return try await store.requestAccess(to: .event)
            }
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    public var isAuthorized: Bool {
        #if canImport(EventKit) && os(iOS)
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .event) == .writeOnly
                || EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
        #else
        return false
        #endif
    }

    /// Whether we have read access (full access, iOS 17+) — required for
    /// reading back user-edited events in pullChanges(...).
    public var hasReadAccess: Bool {
        #if canImport(EventKit) && os(iOS)
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
        #else
        return false
        #endif
    }

    /// Request full (read+write) access. Needed for reverse sync. The user's
    /// system sheet message comes from `NSCalendarsFullAccessUsageDescription`.
    @discardableResult
    public func requestFullAccess() async -> Bool {
        #if canImport(EventKit) && os(iOS)
        do {
            if #available(iOS 17.0, *) {
                return try await store.requestFullAccessToEvents()
            } else {
                return try await store.requestAccess(to: .event)
            }
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    // MARK: - Sync

    /// Create or update the calendar event for a DayPlan. Returns the
    /// EKEvent.eventIdentifier so the caller can persist it on the DayPlan.
    @discardableResult
    public func upsert(
        title: String,
        date: Date,
        timeMinutes: Int,
        durationMinutes: Int = 60,
        notes: String? = nil,
        existingIdentifier: String?
    ) throws -> String {
        #if canImport(EventKit) && os(iOS)
        guard isAuthorized else { throw SyncError.accessDenied }
        let calendar = try ensureCalendar()
        let event: EKEvent
        if let id = existingIdentifier, let existing = store.event(withIdentifier: id) {
            event = existing
        } else {
            event = EKEvent(eventStore: store)
        }
        event.calendar = calendar
        event.title = title
        let dayStart = Calendar.current.startOfDay(for: date)
        let start = Calendar.current.date(byAdding: .minute, value: timeMinutes, to: dayStart) ?? date
        event.startDate = start
        event.endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: start) ?? start
        event.notes = notes
        event.alarms = [EKAlarm(relativeOffset: -30 * 60)]
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
        #else
        throw SyncError.accessDenied
        #endif
    }

    public func delete(identifier: String) throws {
        #if canImport(EventKit) && os(iOS)
        guard isAuthorized else { throw SyncError.accessDenied }
        guard let event = store.event(withIdentifier: identifier) else {
            throw SyncError.eventNotFound
        }
        try store.remove(event, span: .thisEvent)
        #endif
    }

    // MARK: - Reverse sync (calendar → DayPlan)

    /// Snapshot of one event read back from the calendar, used to update
    /// DayPlan when the user edited the event in iPhone Calendar app.
    public struct EventChange: Sendable, Equatable {
        public let identifier: String
        public let title: String
        public let start: Date
        public let isDeleted: Bool
    }

    /// Read all events in our 训练 calendar within the given date range.
    /// Returns a list of EventChange snapshots the caller (DayPlanReverseSyncer)
    /// reconciles against the local DayPlan store. Requires full access.
    public func pullChanges(in range: ClosedRange<Date>) -> [EventChange] {
        #if canImport(EventKit) && os(iOS)
        guard hasReadAccess else { return [] }
        guard let calendar = store.calendars(for: .event)
            .first(where: { $0.title == Self.calendarName }) else { return [] }
        let predicate = store.predicateForEvents(
            withStart: range.lowerBound,
            end: range.upperBound,
            calendars: [calendar]
        )
        let events = store.events(matching: predicate)
        return events.map { ev in
            EventChange(
                identifier: ev.eventIdentifier,
                title: ev.title ?? "",
                start: ev.startDate,
                isDeleted: false
            )
        }
        #else
        return []
        #endif
    }

    /// Subscribe to system "EventStore changed" notifications. The provided
    /// closure runs on the main actor each time the user edits the calendar.
    /// Returns an opaque NSObject token; retain it to keep the subscription
    /// alive (typically stored on the syncer).
    @MainActor
    public func subscribeToChanges(_ handler: @escaping () -> Void) -> Any? {
        #if canImport(EventKit) && os(iOS)
        return NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { _ in handler() }
        #else
        return nil
        #endif
    }

    // MARK: - Helpers

    #if canImport(EventKit) && os(iOS)
    private func ensureCalendar() throws -> EKCalendar {
        if let existing = store.calendars(for: .event)
            .first(where: { $0.title == Self.calendarName }) {
            return existing
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = Self.calendarName
        cal.cgColor = CGColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0) // accent
        guard let source = store.defaultCalendarForNewEvents?.source
                ?? store.sources.first(where: { $0.sourceType == .local })
                ?? store.sources.first
        else { throw SyncError.calendarUnavailable }
        cal.source = source
        try store.saveCalendar(cal, commit: true)
        return cal
    }
    #endif
}
