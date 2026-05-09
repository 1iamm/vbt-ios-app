// TemplateSetSpec.swift
// VBTrainer · 2026-05
//
// Per-set planned parameters within a TemplateItem. When a TemplateItem has
// any setSpecs, those override the legacy targetSets/targetReps/targetWeightKg
// fields — the user has explicitly planned each set's weight / reps / rest.
//
// `kind` distinguishes warm-up sets from work sets. Warm-up sets are shown
// in light grey on the Watch and excluded from VL% baseline calculations.

import Foundation
import SwiftData

public enum TemplateSetKind: String, Codable, CaseIterable, Sendable {
    case warmUp
    case work
}

@Model
public final class TemplateSetSpec {
    @Attribute(.unique) public var id: UUID
    public var index: Int                  // 1-based within the item
    public var kindRaw: String             // TemplateSetKind
    public var weightKg: Double
    public var reps: Int
    public var restSeconds: Int            // rest after this set; 0 = no rest

    public var item: TemplateItem?

    public init(
        id: UUID = UUID(),
        index: Int,
        kind: TemplateSetKind = .work,
        weightKg: Double,
        reps: Int,
        restSeconds: Int = 90
    ) {
        self.id = id
        self.index = index
        self.kindRaw = kind.rawValue
        self.weightKg = weightKg
        self.reps = reps
        self.restSeconds = restSeconds
    }

    public var kind: TemplateSetKind {
        get { TemplateSetKind(rawValue: kindRaw) ?? .work }
        set { kindRaw = newValue.rawValue }
    }
}
