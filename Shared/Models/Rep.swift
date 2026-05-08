// Rep.swift
// VBTrainer · 2026-05
//
// One repetition. Stores all three velocity variants (MV / PV / MPV) so
// the user can switch the default variant per-exercise after the fact
// without losing data.

import Foundation
import SwiftData

@Model
public final class Rep {
    @Attribute(.unique) public var id: UUID
    public var index: Int                       // 1-based within the set
    public var meanVelocity: Double             // m/s, MV
    public var peakVelocity: Double             // m/s, PV
    public var meanPropulsiveVelocity: Double?  // m/s, MPV (nil if not computed)
    public var timestamp: Date
    public var metStatusRaw: String             // MetStatus enum

    public var set: WorkoutSet?

    public init(
        id: UUID = UUID(),
        index: Int,
        meanVelocity: Double,
        peakVelocity: Double,
        meanPropulsiveVelocity: Double? = nil,
        timestamp: Date = Date(),
        metStatus: MetStatus = .met
    ) {
        self.id = id
        self.index = index
        self.meanVelocity = meanVelocity
        self.peakVelocity = peakVelocity
        self.meanPropulsiveVelocity = meanPropulsiveVelocity
        self.timestamp = timestamp
        self.metStatusRaw = metStatus.rawValue
    }

    public var metStatus: MetStatus {
        get { MetStatus(rawValue: metStatusRaw) ?? .met }
        set { metStatusRaw = newValue.rawValue }
    }

    /// Returns the velocity that matches the given variant.
    public func velocity(for variant: VelocityVariant) -> Double {
        switch variant {
        case .mv:  return meanVelocity
        case .mpv: return meanPropulsiveVelocity ?? meanVelocity
        case .pv:  return peakVelocity
        }
    }
}
