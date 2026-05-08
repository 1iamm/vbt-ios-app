// HistoryView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]

    private var grouped: [(day: Date, workouts: [Workout])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: workouts) { cal.startOfDay(for: $0.startedAt) }
        return dict.keys.sorted(by: >).map { key in
            (key, dict[key]!.sorted(by: { $0.startedAt > $1.startedAt }))
        }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.locale = Locale(identifier: "zh-Hans")
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    EmptyStateCard(
                        title: "还没有训练记录",
                        subtitle: "在 Watch 上完成第一次训练后，记录会自动同步到这里"
                    )
                    .padding(Tokens.Space.lg)
                } else {
                    List {
                        ForEach(grouped, id: \.day) { group in
                            Section {
                                ForEach(group.workouts) { w in
                                    NavigationLink {
                                        WorkoutDetailView(workoutId: w.id)
                                    } label: {
                                        row(for: w)
                                    }
                                }
                            } header: {
                                Text(Self.dayFormatter.string(from: group.day))
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("历史")
        }
    }

    private func row(for w: Workout) -> some View {
        HStack(spacing: Tokens.Space.md) {
            Image(systemName: ExerciseLookup.exercise(byId: w.exerciseId)?.sfSymbol ?? "dumbbell.fill")
                .font(.system(size: 22))
                .foregroundStyle(Tokens.Color.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(ExerciseLookup.exercise(byId: w.exerciseId)?.nameZH ?? w.exerciseId)
                    .font(Tokens.Font.headline)
                Text("\(w.sets.count) 组 · \(w.totalReps) reps")
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Self.timeFormatter.string(from: w.startedAt))
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                if let avgVel = avgVelocity(of: w) {
                    Text(String(format: "%.2f m/s", avgVel))
                        .font(Tokens.Font.caption)
                        .foregroundStyle(Tokens.Color.Data.velocity)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func avgVelocity(of w: Workout) -> Double? {
        let allReps = w.sets.flatMap(\.reps)
        guard !allReps.isEmpty else { return nil }
        return allReps.map(\.meanVelocity).reduce(0, +) / Double(allReps.count)
    }
}
