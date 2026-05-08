// TodayView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \ReadinessSnapshot.date, order: .reverse) private var readinessSnaps: [ReadinessSnapshot]

    @State private var hasRefreshed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.xl) {

                    ReadinessRingCard(snapshot: readinessSnaps.first)
                        .padding(.horizontal, Tokens.Space.lg)

                    if let last = workouts.first {
                        Section {
                            WorkoutSummaryCard(workout: last)
                                .padding(.horizontal, Tokens.Space.lg)
                        } header: {
                            sectionHeader("最近训练")
                        }
                    }

                    Section {
                        TrainingHeatmap(workouts: Array(workouts.prefix(120)))
                            .padding(.horizontal, Tokens.Space.lg)
                    } header: {
                        sectionHeader("训练频率 · 最近 30 天")
                    }

                    if workouts.isEmpty && readinessSnaps.isEmpty {
                        EmptyStateCard(
                            title: "还没有训练记录",
                            subtitle: "去 Apple Watch 上开始第一次训练吧"
                        )
                        .padding(.horizontal, Tokens.Space.lg)
                    }

                    Spacer().frame(height: Tokens.Space.xl)
                }
                .padding(.top, Tokens.Space.md)
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())
            .navigationTitle("今天")
            .task {
                guard !hasRefreshed else { return }
                hasRefreshed = true
                if let container = context.container as ModelContainer? {
                    await ReadinessRefresher.refresh(in: container)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Tokens.Font.caption)
            .foregroundStyle(Tokens.Color.secondaryLabel)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, Tokens.Space.lg + Tokens.Space.xs)
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Tokens.Space.sm) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
            Text(title)
                .font(Tokens.Font.headline)
            Text(subtitle)
                .font(Tokens.Font.footnote)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Tokens.Space.xxl)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }
}
