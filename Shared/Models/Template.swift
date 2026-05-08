// Template.swift
// VBTrainer · 2026-05
//
// User-built training template (V1 has NO built-in templates per PRD §M3).
// A template is a sequence of exercise items with target parameters.
// User schedules a template onto a calendar day; Watch executes per-item.

import Foundation
import SwiftData

@Model
public final class Template {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateItem.template)
    public var items: [TemplateItem] = []

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
