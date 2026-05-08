// TrainingHeatmap.swift
// VBTrainer · iPhone · 2026-05
//
// GitHub-style training-frequency heatmap. Each cell = one day; color
// intensity = sum of training volume (kg·reps) on that day.

import SwiftUI

struct TrainingHeatmap: View {
    let workouts: [Workout]
    let days: Int = 30

    private var dailyVolumes: [Date: Double] {
        var dict: [Date: Double] = [:]
        for w in workouts {
            let day = Calendar.current.startOfDay(for: w.startedAt)
            dict[day, default: 0] += w.totalVolumeKg
        }
        return dict
    }

    private var maxVolume: Double {
        dailyVolumes.values.max() ?? 1
    }

    private var grid: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let columns = 6   // 6 columns × 5 rows = 30 days
        let rows = 5
        var dates: [Date] = []
        for offset in 0..<(columns * rows) {
            if let d = cal.date(byAdding: .day, value: -offset, to: today) {
                dates.append(d)
            }
        }
        // Build grid column-major (reverse so most recent is bottom-right)
        var matrix: [[Date?]] = []
        for col in 0..<columns {
            var column: [Date?] = []
            for row in 0..<rows {
                let idx = col * rows + row
                column.append(idx < dates.count ? dates[idx] : nil)
            }
            matrix.append(column)
        }
        return matrix
    }

    var body: some View {
        let cellSize: CGFloat = 38
        let spacing: CGFloat = 4
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            HStack(spacing: spacing) {
                ForEach(0..<grid.count, id: \.self) { col in
                    VStack(spacing: spacing) {
                        ForEach(0..<grid[col].count, id: \.self) { row in
                            cell(date: grid[col][row], size: cellSize)
                        }
                    }
                }
            }
            HStack {
                Text("少")
                    .font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(stepColor(Double(i) / 4.0))
                        .frame(width: 14, height: 14)
                }
                Text("多")
                    .font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                Spacer()
            }
        }
        .padding(Tokens.Space.lg)
        .frame(maxWidth: .infinity)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }

    @ViewBuilder
    private func cell(date: Date?, size: CGFloat) -> some View {
        if let date {
            let volume = dailyVolumes[Calendar.current.startOfDay(for: date)] ?? 0
            let intensity = maxVolume > 0 ? min(1.0, volume / maxVolume) : 0
            RoundedRectangle(cornerRadius: 6)
                .fill(stepColor(intensity))
                .frame(width: size, height: size)
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }

    private func stepColor(_ intensity: Double) -> Color {
        if intensity == 0 {
            return Tokens.Color.fill
        }
        return Tokens.Color.accent.opacity(0.15 + intensity * 0.85)
    }
}
