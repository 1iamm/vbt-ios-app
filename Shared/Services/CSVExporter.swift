// CSVExporter.swift
// VBTrainer · 2026-05
//
// Emit per-rep CSV. UTF-8 BOM for Excel compatibility.

import Foundation

@available(iOS 17.0, watchOS 10.0, *)
public enum CSVExporter {

    public static func csvString(for workouts: [Workout]) -> String {
        var rows: [String] = [
            "workout_id,date,exercise_id,set_index,weight_kg,rep_index,mean_velocity,peak_velocity,mean_propulsive_velocity,met_status,timestamp"
        ]
        let isoFormatter = ISO8601DateFormatter()
        for w in workouts {
            for s in w.sets.sorted(by: { $0.index < $1.index }) {
                for r in s.reps.sorted(by: { $0.index < $1.index }) {
                    let row = [
                        w.id.uuidString,
                        isoFormatter.string(from: w.startedAt),
                        w.exerciseId,
                        "\(s.index)",
                        "\(s.weightKg)",
                        "\(r.index)",
                        "\(r.meanVelocity)",
                        "\(r.peakVelocity)",
                        r.meanPropulsiveVelocity.map { "\($0)" } ?? "",
                        r.metStatusRaw,
                        isoFormatter.string(from: r.timestamp)
                    ].map(escapeField).joined(separator: ",")
                    rows.append(row)
                }
            }
        }
        // BOM + content
        return "\u{FEFF}" + rows.joined(separator: "\n")
    }

    public static func writeFile(workouts: [Workout], to url: URL) throws {
        let content = csvString(for: workouts)
        try content.data(using: .utf8)?.write(to: url)
    }

    private static func escapeField(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}
