// ExerciseTrendView.swift
// VBTrainer · iPhone · 2026-05

import Charts
import SwiftData
import SwiftUI

struct ExerciseTrendView: View {
    let exerciseId: String

    enum Range: String, CaseIterable, Identifiable {
        case d30 = "30天", d90 = "90天", all = "全部"
        var id: String {
            rawValue
        }

        var days: Int? {
            switch self {
            case .d30: 30
            case .d90: 90
            case .all: nil
            }
        }
    }

    @State private var range: Range = .d30
    @Environment(\.modelContext) private var context
    @Query private var workouts: [Workout]

    init(exerciseId: String) {
        self.exerciseId = exerciseId
        let predicate = #Predicate<Workout> { $0.exerciseId == exerciseId }
        _workouts = Query(filter: predicate, sort: [SortDescriptor(\.startedAt, order: .forward)])
    }

    private var filtered: [Workout] {
        guard let days = range.days else { return workouts }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return workouts.filter { $0.startedAt >= cutoff }
    }

    private var exercise: Exercise? {
        ExerciseLookup.exercise(byId: exerciseId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                Picker("时间范围", selection: $range) {
                    ForEach(Range.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Tokens.Space.lg)

                if filtered.isEmpty {
                    EmptyStateCard(
                        title: "没有数据",
                        subtitle: "完成一些 \(exercise?.nameZH ?? "训练") 后这里会显示进步曲线"
                    )
                    .padding(Tokens.Space.lg)
                } else {
                    chartCard("最大重量", color: Tokens.Color.accent) {
                        maxWeightChart
                    }

                    if let lvp = lvpFit {
                        chartCard("e1RM 估算趋势", color: Tokens.Color.Data.velocity) {
                            e1rmChart
                        }
                        LVPChartView(fit: lvp, points: lvpPoints)
                            .padding(.horizontal, Tokens.Space.lg)
                    } else {
                        lvpInsufficientCard
                    }

                    chartCard("同负重平均速度", color: Tokens.Color.Data.velocity) {
                        velocityTrendChart
                    }

                    chartCard("训练量（周聚合）", color: Tokens.Color.Data.volume) {
                        volumeChart
                    }
                }
            }
            .padding(.vertical, Tokens.Space.lg)
        }
        .background(Tokens.Color.groupedBg.ignoresSafeArea())
        .navigationTitle(exercise?.nameZH ?? exerciseId)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Charts

    private var maxWeightChart: some View {
        Chart(filtered) { w in
            let maxW = w.sets.map(\.weightKg).max() ?? 0
            LineMark(
                x: .value("日期", w.startedAt),
                y: .value("重量", maxW)
            )
            .foregroundStyle(Tokens.Color.accent)
            .interpolationMethod(.catmullRom)
            PointMark(
                x: .value("日期", w.startedAt),
                y: .value("重量", maxW)
            )
            .foregroundStyle(Tokens.Color.accent)
        }
        .frame(height: 180)
    }

    private var velocityTrendChart: some View {
        Chart(filtered) { w in
            let allReps = w.sets.flatMap(\.reps)
            let avgV = allReps.isEmpty ? 0 : allReps.map(\.meanVelocity).reduce(0, +) / Double(allReps.count)
            LineMark(
                x: .value("日期", w.startedAt),
                y: .value("速度", avgV)
            )
            .foregroundStyle(Tokens.Color.Data.velocity)
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 180)
    }

    private var e1rmChart: some View {
        Chart(filtered) { w in
            let pts = LVPCalculator.points(
                from: filtered.filter { $0.startedAt <= w.startedAt },
                variant: exercise?.defaultVelocityVariant ?? .mv
            )
            if let fit = LVPCalculator.fit(points: pts),
               let v1 = exercise?.referenceV1RM,
               let e1 = LVPCalculator.estimate1RM(fit: fit, v1RM: v1)
            {
                LineMark(
                    x: .value("日期", w.startedAt),
                    y: .value("e1RM", e1)
                )
                .foregroundStyle(Tokens.Color.Data.velocity)
            }
        }
        .frame(height: 180)
    }

    private var volumeChart: some View {
        let weeks = weeklyVolume()
        return Chart(weeks, id: \.weekStart) { entry in
            BarMark(
                x: .value("周", entry.weekStart),
                y: .value("训练量", entry.volume)
            )
            .foregroundStyle(Tokens.Color.Data.volume)
        }
        .frame(height: 180)
    }

    private struct WeekEntry { let weekStart: Date; let volume: Double }

    private func weeklyVolume() -> [WeekEntry] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { w -> Date in
            cal.dateInterval(of: .weekOfYear, for: w.startedAt)?.start ?? w.startedAt
        }
        return dict
            .map { WeekEntry(weekStart: $0.key, volume: $0.value.reduce(0) { $0 + $1.totalVolumeKg }) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    // MARK: - LVP

    private var lvpPoints: [(load: Double, velocity: Double)] {
        LVPCalculator.points(
            from: filtered,
            variant: exercise?.defaultVelocityVariant ?? .mv
        )
    }

    private var lvpFit: LVPFit? {
        LVPCalculator.fit(points: lvpPoints)
    }

    private var lvpInsufficientCard: some View {
        let distinctLoads = Set(lvpPoints.map { round($0.load * 100) / 100 }).count
        let need = LVPCalculator.minDistinctLoads - distinctLoads
        return VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Label("力速曲线 (LVP)", systemImage: "chart.xyaxis.line")
                .font(Tokens.Font.headline)
            Text("再记录 \(max(need, 0)) 组不同重量的数据即可解锁 LVP 与 e1RM 估算。")
                .font(Tokens.Font.footnote)
                .foregroundStyle(Tokens.Color.secondaryLabel)
            Text("当前已有 \(distinctLoads) 个不同重量")
                .font(Tokens.Font.caption)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(Tokens.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .padding(.horizontal, Tokens.Space.lg)
    }

    // MARK: - Helpers

    private func chartCard(_ title: String, color _: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Text(title).font(Tokens.Font.headline)
            content()
        }
        .padding(Tokens.Space.lg)
        .cardStyle()
        .padding(.horizontal, Tokens.Space.lg)
    }
}
