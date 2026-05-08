// WorkoutDetailView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workoutId: UUID

    @Environment(\.modelContext) private var context
    @Query private var workouts: [Workout]

    init(workoutId: UUID) {
        self.workoutId = workoutId
        let predicate = #Predicate<Workout> { $0.id == workoutId }
        _workouts = Query(filter: predicate)
    }

    private var workout: Workout? { workouts.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                if let workout {
                    headerSummary(workout)
                    ComprehensiveChartView(workout: workout)
                        .frame(height: 280)
                        .padding(.horizontal, Tokens.Space.lg)
                    HeartRateZonesDonut(workout: workout)
                        .padding(.horizontal, Tokens.Space.lg)
                    SetTableView(workout: workout)
                        .padding(.horizontal, Tokens.Space.lg)
                } else {
                    EmptyStateCard(
                        title: "未找到训练记录",
                        subtitle: "可能已被删除或未同步"
                    )
                    .padding(Tokens.Space.lg)
                }
            }
            .padding(.vertical, Tokens.Space.lg)
        }
        .background(Tokens.Color.groupedBg.ignoresSafeArea())
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let id = workout?.exerciseId {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ExerciseTrendView(exerciseId: id)
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
            }
        }
    }

    private var exerciseName: String {
        guard let id = workout?.exerciseId else { return "训练详情" }
        return ExerciseLookup.exercise(byId: id)?.nameZH ?? id
    }

    private func headerSummary(_ w: Workout) -> some View {
        let allReps = w.sets.flatMap(\.reps)
        let avgVel = allReps.isEmpty ? 0 : allReps.map(\.meanVelocity).reduce(0, +) / Double(allReps.count)
        let avgVL = w.sets.isEmpty ? 0 : w.sets.map(\.velocityLossPercent).reduce(0, +) / Double(w.sets.count)
        let durationMin = Int(w.durationSeconds / 60)

        return VStack(spacing: Tokens.Space.lg) {
            HStack(spacing: 0) {
                stat("总Reps", "\(w.totalReps)", color: Tokens.Color.label)
                Divider().frame(height: 36)
                stat("平均速度", String(format: "%.2f", avgVel), unit: "m/s", color: Tokens.Color.Data.velocity)
                Divider().frame(height: 36)
                stat("VL%", String(format: "%.0f", avgVL), unit: "%", color: Tokens.Color.Data.velocityLoss)
                Divider().frame(height: 36)
                stat("时长", "\(durationMin)", unit: "min", color: Tokens.Color.label)
            }
            .padding(Tokens.Space.lg)
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
        }
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func stat(_ label: String, _ value: String, unit: String? = nil, color: Color) -> some View {
        VStack(spacing: 2) {
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
        .frame(maxWidth: .infinity)
    }
}
