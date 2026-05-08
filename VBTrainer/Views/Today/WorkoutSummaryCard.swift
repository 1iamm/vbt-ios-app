// WorkoutSummaryCard.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct WorkoutSummaryCard: View {
    let workout: Workout

    private var exerciseName: String {
        ExerciseLookup.exercise(byId: workout.exerciseId)?.nameZH ?? workout.exerciseId
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: workout.startedAt)
    }

    private var avgVelocity: Double {
        let allReps = workout.sets.flatMap { $0.reps }
        guard !allReps.isEmpty else { return 0 }
        return allReps.map(\.meanVelocity).reduce(0, +) / Double(allReps.count)
    }

    private var avgVL: Double {
        guard !workout.sets.isEmpty else { return 0 }
        return workout.sets.map(\.velocityLossPercent).reduce(0, +) / Double(workout.sets.count)
    }

    var body: some View {
        NavigationLink {
            WorkoutDetailView(workoutId: workout.id)
        } label: {
            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exerciseName)
                            .font(Tokens.Font.headline)
                            .foregroundStyle(Tokens.Color.label)
                        Text(dateString)
                            .font(Tokens.Font.footnote)
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }

                Divider()

                HStack(spacing: Tokens.Space.lg) {
                    stat("总Reps", "\(workout.totalReps)")
                    Divider().frame(height: 30)
                    stat("平均速度", String(format: "%.2f", avgVelocity), unit: "m/s", color: Tokens.Color.Data.velocity)
                    Divider().frame(height: 30)
                    stat("VL%", String(format: "%.0f", avgVL), unit: "%", color: Tokens.Color.Data.velocityLoss)
                }
            }
            .padding(Tokens.Space.lg)
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private func stat(_ label: String, _ value: String, unit: String? = nil, color: Color = Tokens.Color.label) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(Tokens.Font.numericMedium)
                    .foregroundStyle(color)
                    .monospacedDigit()
                if let unit {
                    Text(unit).font(Tokens.Font.footnote).foregroundStyle(Tokens.Color.secondaryLabel)
                }
            }
            Text(label)
                .font(Tokens.Font.caption)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
