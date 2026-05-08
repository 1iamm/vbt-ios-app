// PaperCitation.swift
// VBTrainer · 2026-05
//
// A literature citation. Used by ExerciseLibrary metadata and (in later
// proposals) by every algorithm constant via doc-comment reference.

import Foundation

public struct PaperCitation: Identifiable, Codable, Hashable, Sendable {
    public let id: String        // e.g. "gonzalezBadillo2010Velocity"
    public let authors: String
    public let year: Int
    public let title: String
    public let journal: String
    public let doi: String?
    public let url: String       // PubMed / PMC / DOI — must be https://
    public let topic: CitationTopic

    public init(
        id: String,
        authors: String,
        year: Int,
        title: String,
        journal: String,
        doi: String? = nil,
        url: String,
        topic: CitationTopic
    ) {
        self.id = id
        self.authors = authors
        self.year = year
        self.title = title
        self.journal = journal
        self.doi = doi
        self.url = url
        self.topic = topic
    }

    /// Short inline form: "González-Badillo & Sánchez-Medina (2010)"
    public var shortForm: String {
        "\(authors) (\(year))"
    }
}
