// SetTableView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct SetTableView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Text("各组数据")
                .font(Tokens.Font.headline)

            if workout.sets.isEmpty {
                Text("无组数据")
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            } else {
                VStack(spacing: 0) {
                    headerRow
                    Divider()
                    ForEach(workout.sets.sorted(by: { $0.index < $1.index })) { s in
                        row(set: s)
                        if s.id != workout.sets.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(Tokens.Space.lg)
        .cardStyle()
    }

    private var headerRow: some View {
        HStack {
            cellLabel("组", alignment: .leading)
            cellLabel("重量")
            cellLabel("Reps")
            cellLabel("速度")
            cellLabel("VL%", alignment: .trailing)
        }
        .padding(.vertical, Tokens.Space.xs)
    }

    private func row(set: WorkoutSet) -> some View {
        HStack {
            cell("\(set.index)", alignment: .leading, weight: .semibold)
            cell(String(format: "%.1f", set.weightKg))
            cell("\(set.reps.count)")
            cell(String(format: "%.2f", set.avgVelocity), color: Tokens.Color.Data.velocity)
            cell(String(format: "%.0f", set.velocityLossPercent), alignment: .trailing, color: Tokens.Color.Data.velocityLoss)
        }
        .padding(.vertical, Tokens.Space.sm)
    }

    private func cellLabel(_ text: String, alignment: Alignment = .center) -> some View {
        Text(text)
            .font(Tokens.Font.caption)
            .foregroundStyle(Tokens.Color.secondaryLabel)
            .textCase(.uppercase)
            .tracking(0.3)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func cell(
        _ text: String,
        alignment: Alignment = .center,
        weight: Font.Weight = .regular,
        color: Color = Tokens.Color.label
    ) -> some View {
        Text(text)
            .font(.system(size: 15, weight: weight, design: .rounded))
            .foregroundStyle(color)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}
