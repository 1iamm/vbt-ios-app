// StatsView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 redesign · 5 步动线第 5 步 · "统计 · 周环比是头条":
//   - 头条卡：本周 vs 上周（训练量 / 平均速度 / 平均 VL% / 训练次数）
//   - e1RM 主项进展：top 3 exercises 的 e1RM 走势（Charts）
//   - Readiness 趋势：最近 14 天 readiness score 折线
//   - PR 列表入口

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \ReadinessSnapshot.date, order: .reverse) private var readiness: [ReadinessSnapshot]
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) private var prs: [PersonalRecord]

    private var goal: TrainingGoal { profiles.first?.trainingGoal ?? .strength }
    private var accent: Color { GoalTheme.accent(for: goal) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headlineCard
                    SectionHeader(title: "e1RM · 主项进展", action: "全部 →", accent: accent)
                    e1rmList
                    SectionHeader(title: "Readiness · 14 天")
                    readinessChartCard
                    SectionHeader(title: "PR 记录", action: "查看 →", accent: accent)
                    prsList
                    Spacer().frame(height: 24)
                }
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())
            .navigationTitle("统计")
        }
    }

    // MARK: - Headline (week-over-week)

    private var headlineCard: some View {
        let h = WeekOverWeekStats.headline(context: context)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("本周 vs 上周")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(weekRangeLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                deltaTile(label: "训练量",
                          value: h.thisWeekVolume >= 1000 ?
                            String(format: "%.1ft", h.thisWeekVolume / 1000) :
                            String(format: "%.0fkg", h.thisWeekVolume),
                          delta: h.deltaPercent(h.thisWeekVolume, h.lastWeekVolume),
                          higherIsBetter: true)
                deltaTile(label: "训练次数",
                          value: "\(h.thisWeekCount)",
                          delta: pct(h.thisWeekCount, h.lastWeekCount),
                          higherIsBetter: true)
                deltaTile(label: "平均速度",
                          value: String(format: "%.2f", h.thisWeekAvgVelocity),
                          delta: h.deltaPercent(h.thisWeekAvgVelocity, h.lastWeekAvgVelocity),
                          higherIsBetter: true)
                deltaTile(label: "平均 VL%",
                          value: String(format: "%.0f%%", h.thisWeekAvgVL),
                          delta: h.deltaPercent(h.thisWeekAvgVL, h.lastWeekAvgVL),
                          higherIsBetter: false)
            }
        }
        .padding(14)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var weekRangeLabel: String {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start,
              let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M·d"
        return "\(f.string(from: weekStart)) — \(f.string(from: weekEnd))"
    }

    private func pct(_ a: Int, _ b: Int) -> Double {
        guard b > 0 else { return a > 0 ? 100 : 0 }
        return Double(a - b) / Double(b) * 100
    }

    private func deltaTile(label: String, value: String, delta: Double, higherIsBetter: Bool) -> some View {
        let goodDelta = higherIsBetter ? delta >= 0 : delta <= 0
        let deltaColor: Color = abs(delta) < 0.5 ? Tokens.Color.tertiaryLabel
            : (goodDelta ? Tokens.Color.success : Tokens.Color.danger)
        let deltaText: String = abs(delta) < 0.5 ? "持平"
            : "\(delta > 0 ? "+" : "")\(Int(delta))%"
        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .textCase(.uppercase)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.4)
                Text(deltaText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(deltaColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Tokens.Color.fill, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - e1RM list

    @ViewBuilder
    private var e1rmList: some View {
        let groups = Dictionary(grouping: workouts) { $0.exerciseId }
            .map { (id, ws) in
                (id, ws.sorted(by: { $0.startedAt > $1.startedAt }))
            }
            .filter { !$0.1.isEmpty }
            .sorted { $0.1.count > $1.1.count }
            .prefix(3)

        if groups.isEmpty {
            EmptyStateCard(title: "训练数据不足", subtitle: "完成几次训练后，e1RM 趋势会出现")
                .padding(.horizontal, Tokens.Space.lg)
                .padding(.bottom, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let id = group.0
                    let ws = group.1
                    NavigationLink {
                        ExerciseTrendView(exerciseId: id)
                    } label: {
                        e1rmRow(exerciseId: id, recent: Array(ws.prefix(8)))
                    }
                    .buttonStyle(.plain)
                    if id != groups.last?.0 {
                        Divider().padding(.leading, 32)
                    }
                }
            }
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.bottom, 12)
        }
    }

    private func e1rmRow(exerciseId: String, recent: [Workout]) -> some View {
        let name = ExerciseLookup.exercise(byId: exerciseId)?.nameZH ?? exerciseId
        let e1rms: [Double] = recent.compactMap { w in
            // Epley: e1RM = weight × (1 + reps / 30); pick top set per workout
            w.sets.map { set -> Double in
                let reps = set.reps.count
                guard reps > 0 else { return 0 }
                return set.weightKg * (1 + Double(reps) / 30.0)
            }.max()
        }.filter { $0 > 0 }.reversed()
        let last = e1rms.last ?? 0
        let first = e1rms.first ?? last
        let delta = first > 0 ? (last - first) / first * 100 : 0
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                Text("e1RM \(Int(last)) kg")
                    .font(.system(size: 12, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Spacer(minLength: 0)
            if e1rms.count >= 2 {
                MiniSparkline(values: Array(e1rms), color: accent, width: 84, height: 28)
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(delta >= 0 ? "+" : "")\(String(format: "%.1f", delta))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(delta >= 0 ? Tokens.Color.success : Tokens.Color.danger)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    // MARK: - Readiness chart

    private struct ReadinessPoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Int
    }

    private var readinessChartCard: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let points: [ReadinessPoint] = readiness
            .filter { $0.date >= cutoff }
            .compactMap { snap in
                snap.score.map { ReadinessPoint(date: snap.date, score: $0) }
            }
            .sorted { $0.date < $1.date }
        return VStack(alignment: .leading, spacing: 6) {
            if points.isEmpty {
                Text("Readiness 数据建立中")
                    .font(.system(size: 13))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            } else {
                Chart(points) { p in
                    LineMark(
                        x: .value("date", p.date),
                        y: .value("score", p.score)
                    )
                    .foregroundStyle(accent)
                    .interpolationMethod(.monotone)
                    AreaMark(
                        x: .value("date", p.date),
                        y: .value("score", p.score)
                    )
                    .foregroundStyle(accent.opacity(0.18))
                    .interpolationMethod(.monotone)
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, 4)
                Text("最近 \(points.count) 天 · 平均 \(Int(Double(points.map(\.score).reduce(0, +)) / Double(points.count)))")
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .padding(14)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.bottom, 12)
    }

    // MARK: - PR list

    @ViewBuilder
    private var prsList: some View {
        if prs.isEmpty {
            EmptyStateCard(title: "尚无 PR", subtitle: "在训练中创造记录，会出现在这里")
                .padding(.horizontal, Tokens.Space.lg)
                .padding(.bottom, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(prs.prefix(5)) { pr in
                    NavigationLink {
                        PRListView()
                    } label: {
                        prRow(pr)
                    }
                    .buttonStyle(.plain)
                    if pr.id != prs.prefix(5).last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.bottom, 12)
        }
    }

    private func prRow(_ pr: PersonalRecord) -> some View {
        let name = ExerciseLookup.exercise(byId: pr.exerciseId)?.nameZH ?? pr.exerciseId
        let kindLabel: String = {
            switch pr.kind {
            case .maxWeight:            return "最大重量"
            case .e1RM:                 return "e1RM"
            case .maxVolume:            return "最大训练量"
            case .maxSingleRepVelocity: return "最快单 rep"
            case .maxCMJ:               return "最高 CMJ"
            }
        }()
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Tokens.Color.success.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Tokens.Color.success)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 14, weight: .semibold))
                Text(kindLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Spacer()
            Text(formatPRValue(pr))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private func formatPRValue(_ pr: PersonalRecord) -> String {
        switch pr.kind {
        case .maxWeight, .e1RM, .maxVolume:
            return "\(Int(pr.value))kg"
        case .maxSingleRepVelocity:
            return String(format: "%.2f m/s", pr.value)
        case .maxCMJ:
            return "\(Int(pr.value))cm"
        }
    }
}
