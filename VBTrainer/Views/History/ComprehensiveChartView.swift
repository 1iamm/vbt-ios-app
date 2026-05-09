// ComprehensiveChartView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 redesign — comprehensive workout timeline:
//   • Discrete colored band on top: per-exercise hue, per-set chip with gaps
//   • Heart-rate line  (left axis, BPM 40–220)
//   • Per-rep velocity scatter  (right axis, 0–1.5 m/s)
//   • Per-set VL%  (dashed segment on velocity axis, only spans the set)
//   • Dual X axis: absolute time (主) + relative +Nm (三级灰)
//   • Tappable legend: hide/show each series

import SwiftUI
import Charts

struct ComprehensiveChartView: View {
    let workout: Workout

    @State private var showHR = true
    @State private var showVelocity = true
    @State private var showVL = true

    // MARK: - Derived data

    private var heartRateSamples: [HeartRateSample] {
        guard let data = workout.heartRateSamplesData else { return [] }
        return (try? JSONDecoder().decode([HeartRateSample].self, from: data)) ?? []
    }

    private var orderedSets: [WorkoutSet] {
        workout.sets.sorted { $0.index < $1.index }
    }

    private var workoutStart: Date { workout.startedAt }
    private var workoutEnd: Date {
        if let e = workout.endedAt { return e }
        let lastRep = orderedSets.flatMap { $0.reps.map(\.timestamp) }.max()
        return lastRep ?? workoutStart.addingTimeInterval(60)
    }
    private var timeDomain: ClosedRange<Date> { workoutStart...workoutEnd }
    private var totalSeconds: TimeInterval {
        max(60, workoutEnd.timeIntervalSince(workoutStart))
    }

    /// Map exercise id → palette color.
    /// Uses 5-color data palette (heartRate=不能用 / velocity=blue / volume=orange / velocityLoss=purple / sleep=indigo)
    /// plus 3 extra goal-derived hues so up to 8 distinct exercises render cleanly.
    private static let exerciseColors: [Color] = [
        Tokens.Color.Data.velocity,
        Tokens.Color.Data.volume,
        Tokens.Color.Data.velocityLoss,
        Tokens.Color.Data.sleep,
        Color(hex: "5AC8FA"), // light cyan
        Color(hex: "30D158"), // green
        Color(hex: "FF9F0A"), // amber
        Color(hex: "BF5AF2"), // pink-purple
    ]

    private var exerciseColorMap: [String: Color] {
        let ids = Array(NSOrderedSet(array: orderedSets.map(\.workout?.exerciseId).compactMap { $0 })) as? [String]
            ?? [workout.exerciseId]
        var map: [String: Color] = [:]
        for (i, id) in ids.enumerated() {
            map[id] = Self.exerciseColors[i % Self.exerciseColors.count]
        }
        return map
    }

    /// Each set's [start, end] within the timeline (start = first rep, end = last rep).
    private var setIntervals: [(set: WorkoutSet, start: Date, end: Date, color: Color)] {
        orderedSets.compactMap { set in
            let reps = set.reps.sorted { $0.index < $1.index }
            guard let first = reps.first?.timestamp, let last = reps.last?.timestamp else { return nil }
            // Make zero-length sets (single rep) a tiny visible band:
            let end = last > first ? last : last.addingTimeInterval(2)
            let id = set.workout?.exerciseId ?? workout.exerciseId
            let color = exerciseColorMap[id] ?? Tokens.Color.Data.velocity
            return (set, first, end, color)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            legend
            chart
                .frame(minHeight: 220)
            xAxisDualLabels
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            legendButton(color: Tokens.Color.Data.heartRate, label: "心率",
                         isOn: $showHR, style: .solid)
            legendButton(color: Tokens.Color.Data.velocity, label: "速度",
                         isOn: $showVelocity, style: .scatter)
            legendButton(color: Tokens.Color.Data.velocityLoss, label: "VL%",
                         isOn: $showVL, style: .dashed)
            Spacer()
        }
        .font(.system(size: 11, weight: .medium))
    }

    enum LegendStyle { case solid, scatter, dashed }

    private func legendButton(color: Color, label: String, isOn: Binding<Bool>, style: LegendStyle) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isOn.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 5) {
                glyph(color: color, style: style)
                    .opacity(isOn.wrappedValue ? 1.0 : 0.35)
                Text(label)
                    .foregroundStyle(isOn.wrappedValue ? Tokens.Color.label : Tokens.Color.tertiaryLabel)
            }
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(isOn.wrappedValue ? color.opacity(0.10) : Color.clear,
                        in: Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func glyph(color: Color, style: LegendStyle) -> some View {
        switch style {
        case .solid:
            Capsule().fill(color).frame(width: 14, height: 3)
        case .scatter:
            HStack(spacing: 2) {
                Circle().fill(color).frame(width: 4, height: 4)
                Circle().fill(color).frame(width: 4, height: 4)
                Circle().fill(color).frame(width: 4, height: 4)
            }
            .frame(width: 14)
        case .dashed:
            ZStack {
                Capsule().fill(color.opacity(0.0)).frame(width: 14, height: 3)
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(color).frame(width: 3, height: 2)
                    }
                }
            }
            .frame(width: 14)
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Heart-rate line
            if showHR {
                ForEach(heartRateSamples, id: \.timestamp) { s in
                    LineMark(
                        x: .value("时间", s.timestamp),
                        y: .value("BPM", Double(s.bpm)),
                        series: .value("series", "hr")
                    )
                    .foregroundStyle(Tokens.Color.Data.heartRate)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(.init(lineWidth: 2))
                }
            }

            // Per-rep velocity scatter (mapped onto the BPM axis space)
            if showVelocity {
                ForEach(orderedSets) { set in
                    ForEach(set.reps) { rep in
                        PointMark(
                            x: .value("时间", rep.timestamp),
                            y: .value("BPM-mapped",
                                       velocityToBpm(rep.meanVelocity))
                        )
                        .foregroundStyle(Tokens.Color.Data.velocity)
                        .symbol(.circle)
                        .symbolSize(40)
                    }
                }
            }

            // Per-set VL% dashed segment — only spans the set's time, drawn on
            // the velocity axis (mapped to BPM space).
            if showVL {
                ForEach(setIntervals.indices, id: \.self) { i in
                    let iv = setIntervals[i]
                    let firstV = iv.set.reps.first?.meanVelocity ?? 0
                    let lastV  = iv.set.reps.last?.meanVelocity  ?? firstV
                    let vl = firstV > 0 ? max(0, (firstV - lastV) / firstV * 100) : 0
                    LineMark(
                        x: .value("start", iv.start),
                        y: .value("vl",   bpmYForVL(vl)),
                        series: .value("series", "vl-\(i)")
                    )
                    .foregroundStyle(Tokens.Color.Data.velocityLoss)
                    .lineStyle(.init(lineWidth: 1.5, dash: [4, 3]))
                    LineMark(
                        x: .value("end", iv.end),
                        y: .value("vl",  bpmYForVL(vl)),
                        series: .value("series", "vl-\(i)")
                    )
                    .foregroundStyle(Tokens.Color.Data.velocityLoss)
                    .lineStyle(.init(lineWidth: 1.5, dash: [4, 3]))
                }
            }
        }
        .chartXScale(domain: timeDomain)
        .chartYScale(domain: 40...220)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: [60, 100, 140, 180, 220]) { v in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let bpm = v.as(Int.self) {
                        Text("\(bpm)")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(Tokens.Color.tertiaryLabel)
                    }
                }
            }
            AxisMarks(position: .trailing, values: [40, 80, 120, 160, 200]) { v in
                AxisValueLabel {
                    if let bpm = v.as(Int.self) {
                        Text(String(format: "%.1f", bpmToVelocity(Double(bpm))))
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(showVelocity ? Tokens.Color.Data.velocity : Tokens.Color.tertiaryLabel)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // Top exercise/set band — draw at y=0 with discrete chips.
                    setBandView(proxy: proxy, plot: geo.size)
                }
            }
        }
        .padding(.top, 30) // leave room for the top set band
    }

    /// Map velocity 0..1.5 m/s onto BPM domain (40..220) so a single Y axis can render both.
    private func velocityToBpm(_ v: Double) -> Double {
        // 0 m/s  → 40 BPM,   1.5 m/s → 220 BPM
        return 40 + min(1.5, max(0, v)) / 1.5 * 180
    }

    private func bpmToVelocity(_ b: Double) -> Double {
        return min(1.5, max(0, (b - 40) / 180.0 * 1.5))
    }

    /// Map VL% onto the velocity axis at a fixed visual height.
    /// Approximation: VL% 0 → 1.20 m/s line, VL% 50 → 0.30 m/s line.
    private func bpmYForVL(_ vl: Double) -> Double {
        let v = max(0, min(50, vl))
        let velocityLine = 1.20 - (v / 50) * (1.20 - 0.30)
        return velocityToBpm(velocityLine)
    }

    @ViewBuilder
    private func setBandView(proxy: ChartProxy, plot: CGSize) -> some View {
        let yOffset: CGFloat = -22
        // proxy.plotAreaFrame is `Anchor<CGRect>?`, not a usable rect; we
        // already get the plot size from the ChartProxy.plotAreaSize, so
        // anchor x=0 in the local coordinate space.
        ZStack(alignment: .topLeading) {
            ForEach(setIntervals.indices, id: \.self) { i in
                let iv = setIntervals[i]
                if let xStart = proxy.position(forX: iv.start),
                   let xEnd   = proxy.position(forX: iv.end) {
                    let x = min(xStart, xEnd)
                    let w = max(4, abs(xEnd - xStart))
                    VStack(alignment: .leading, spacing: 1) {
                        if i == 0 || iv.set.workout?.exerciseId != setIntervals[i - 1].set.workout?.exerciseId {
                            Text(exerciseShortName(for: iv.set.workout?.exerciseId ?? workout.exerciseId))
                                .font(.system(size: 8, weight: .semibold))
                                .tracking(0.6)
                                .foregroundStyle(iv.color)
                                .textCase(.uppercase)
                                .offset(y: -10)
                        }
                        RoundedRectangle(cornerRadius: 2)
                            .fill(iv.color)
                            .frame(width: w, height: 6)
                            .overlay(alignment: .topLeading) {
                                Text("\(Int(iv.set.weightKg))kg×\(iv.set.reps.count)")
                                    .font(.system(size: 8, design: .rounded))
                                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                                    .offset(y: -12)
                            }
                    }
                    .offset(x: x, y: yOffset)
                }
            }
        }
    }

    private func exerciseShortName(for id: String) -> String {
        ExerciseLookup.exercise(byId: id)?.nameZH ?? id
    }

    // MARK: - Dual X axis labels

    private var xAxisDualLabels: some View {
        GeometryReader { geo in
            let count = 5
            ForEach(0..<count, id: \.self) { i in
                let frac = Double(i) / Double(count - 1)
                let date = workoutStart.addingTimeInterval(totalSeconds * frac)
                let x = geo.size.width * frac
                VStack(alignment: .center, spacing: 1) {
                    Text(absoluteHHMM(date))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Tokens.Color.label)
                    Text("+\(Int(totalSeconds * frac / 60))m")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }
                .frame(width: 60)
                .position(x: x, y: 14)
            }
        }
        .frame(height: 30)
    }

    private func absoluteHHMM(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
