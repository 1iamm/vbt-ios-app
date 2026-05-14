// ExerciseLookup.swift
// VBTrainer · 2026-05
//
// Convenience accessors over the static exerciseLibrary array.

import Foundation

public enum ExerciseLookup {
    /// O(n) lookup by id — fine for V1 (30 exercises). If we ever exceed
    /// ~200, switch to a precomputed dictionary.
    public static func exercise(byId id: String) -> Exercise? {
        exerciseLibrary.first { $0.id == id }
    }

    public static func exercises(in category: ExerciseCategory) -> [Exercise] {
        exerciseLibrary.filter { $0.category == category }
    }

    /// Categorized for UI list rendering.
    public static var grouped: [(category: ExerciseCategory, items: [Exercise])] {
        ExerciseCategory.allCases.map { cat in
            (cat, exerciseLibrary.filter { $0.category == cat })
        }
    }

    public static var totalCount: Int {
        exerciseLibrary.count
    }
}
