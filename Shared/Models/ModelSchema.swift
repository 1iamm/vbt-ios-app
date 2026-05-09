// ModelSchema.swift
// VBTrainer · 2026-05
//
// Versioned schema for SwiftData. V1 is the only version. Future migrations
// (V2 adds AI-related fields) will declare V2 alongside this file.

import Foundation
import SwiftData

/// All `@Model` classes that make up the V1 schema. Used when constructing
/// the `ModelContainer` so SwiftData knows the full universe of types.
public enum VBTSchemaV1 {
    public static let allModels: [any PersistentModel.Type] = [
        UserProfile.self,
        Workout.self,
        WorkoutSet.self,
        Rep.self,
        JumpTest.self,
        ReadinessSnapshot.self,
        Template.self,
        TemplateItem.self,
        TemplateSetSpec.self,
        DayPlan.self,
        PersonalRecord.self,
    ]
}
