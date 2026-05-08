## ADDED Requirements

### Requirement: CSV 导出

`CSVExporter.export(workouts:to:)` SHALL emit a CSV file with the schema:

```
workout_id,date,exercise_id,set_index,weight_kg,rep_index,mean_velocity,peak_velocity,mean_propulsive_velocity,met_status,timestamp
```

One row per rep. UTF-8 with BOM for Excel compatibility.

#### Scenario: All reps appear

- **WHEN** exporting a workout with 3 sets × 5 reps
- **THEN** the CSV has 15 data rows + 1 header row

### Requirement: JSON 导出

`JSONExporter.exportAll(in:)` SHALL produce a single JSON file containing arrays of `WorkoutSnapshot`, `JumpTestSnapshot`, `ReadinessSnapshot` and `PersonalRecord` (Codable round-trippable).

### Requirement: ShareSheet 集成

`ProfileView` SHALL present `UIActivityViewController` so the user can save / share the exported file.
