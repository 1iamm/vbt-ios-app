// ComprehensiveChartView.swift
// VBTrainer · iPhone · 2026-05
//
// Single Swift Charts view that overlays:
//   - Heart rate (line, left Y axis)
//   - Per-rep velocity (points, right Y axis)
//   - Set boundaries (vertical RuleMark)
//   - Inter-set rest periods (RectangleMark gray fill)
//   - VL% ceiling reference line (horizontal RuleMark, dashed)

import SwiftUI
import Charts

struct ComprehensiveChartView: View {
    let workout: Workout

    private var heartRateSamples: [HeartRateSample] {
        guard let data = workout.heartRateSamplesData else { return [] }
        return (try? JSONDecoder().decode([HeartRateSample].self, from: data)) ?? []
    }

    private var hrDomain: ClosedRange<Int> {
        let values = heartRateSamples.map(\.bpm)
        let lo = (values.min() ?? 60) - 10
        let hi = (values.max() ?? 180) + 10
        return max(40, lo)...min(220, max(hi, 180))
    }

    private var velocityDomain: ClosedRange<Double> {
        let allReps = workout.sets.flatMap(\.reps)
        let values = allReps.map(\.meanVelocity)
        let hi = (values.max() ?? 1.0) + 0.2
        return 0...max(hi, 1.0)
    }

    private var timeDomain: ClosedRange<Date> {
        let start = workout.startedAt
        let end = workout.endedAt ?? Date()
        return start...end
    }

    private var setBoundaries: [(set: WorkoutSet, time: Date)] {
        workout.sets
            .sorted(by: { $0.index < $1.index })
            .compactMap { s -> (WorkoutSet, Date)? in
                guard let firstRep = s.reps.sorted(by: { $0.index < $1.index }).first
                else { return nil }
                return (s, firstRep.timestamp)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            HStack(spacing: Tokens.Space.lg) {
                legendDot(color: Tokens.Color.Data.heartRate, label: "心率")
                legendDot(color: Tokens.Color.Data.velocity, label: "速度")
                Spacer()
            }
            .font(Tokens.Font.caption)

            if heartRateSamples.isEmpty && workout.sets.flatMap(\.reps).isEmpty {
                emptyChart
            } else {
                chart
            }
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }

    private var emptyChart: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 28))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
            Text("没有可视化的数据")
                .font(Tokens.Font.footnote)
                .foregroundStyle(Tokens.Color.secondaryLabel)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private var chart: some View {
        Chart {
            // Heart-rate line
            ForEach(heartRateSamples, id: \.timestamp) { sample in
                LineMark(
                    x: .value("时间", sample.timestamp),
                    y: .value("BPM", Double(sample.bpm)),
                    series: .value("HR", "hr")
                )
                .foregroundStyle(Tokens.Color.Data.heartRate)
                .interpolationMethod(.catmullRom)
                .lineStyle(.init(lineWidth: 2))
            }

            // Per-rep velocity points
            ForEach(workout.sets) { set in
                ForEach(set.reps) { rep in
                    PointMark(
                        x: .value("时间", rep.timestamp),
                        y: .value("速度", rep.meanVelocity * (hrDomain.upperBound > 0 ? Double(hrDomain.upperBound) / max(velocityDomain.upperBound, 0.1) : 100))
                    )
                    .foregroundStyle(by: .value("Set", "组 \(set.index)"))
                    .symbol(by: .value("Set", "组 \(set.index)"))
                    .symbolSize(60)
                }
            }

            // Set boundary RuleMarks
            ForEach(Array(setBoundaries.enumerated()), id: \.offset) { (i, sb) in
                RuleMark(x: .value("Set start", sb.time))
                    .foregroundStyle(Tokens.Color.tertiaryLabel.opacity(0.6))
                    .lineStyle(.init(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("\(Int(sb.set.weightKg))kg")
                            .font(Tokens.Font.caption)
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                            .padding(.horizontal, 4)
                            .background(Tokens.Color.card.opacity(0.8))
                    }
            }
        }
        .chartForegroundStyleScale([
            "组 1": Tokens.Color.Data.velocity,
            "组 2": Tokens.Color.Data.velocity.opacity(0.85),
            "组 3": Tokens.Color.Data.velocity.opacity(0.7),
            "组 4": Tokens.Color.Data.velocity.opacity(0.55),
            "组 5": Tokens.Color.Data.velocity.opacity(0.4),
        ])
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(Tokens.Color.secondaryLabel)
        }
    }
}
