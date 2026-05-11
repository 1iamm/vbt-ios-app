// LiveWorkoutView.swift
// VBTrainer · iOS · 2026-05
//
// fullScreenCover surfaced from TodayView when a Watch training session is
// live. Renders one of four phase-specific subviews driven by
// LiveWorkoutStore.shared.payload.phase:
//   .ready / .repDetected → SetActiveView   (current speed / rep / VL%)
//   .setEnded             → SetEndedView    (bar chart, 4s auto-advance)
//   .restCountdown        → RestView        (countdown + +15s + previews)
//   .workoutEnded         → handled by cover dismiss
//
// Per Round-3 PM consensus.

import SwiftUI

@available(iOS 17.0, *)
struct LiveWorkoutView: View {
    @ObservedObject var store = LiveWorkoutStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let p = store.payload {
                switch p.phase {
                case .ready, .repDetected:
                    SetActiveView(payload: p)
                case .setEnded:
                    SetEndedView(payload: p)
                case .restCountdown:
                    RestView(payload: p)
                case .workoutEnded:
                    Color.clear.onAppear { dismiss() }
                }
            } else {
                ReadyOverlay()
            }
        }
        // .overlay(alignment:) 只占角落 hit-test 区域，不像之前 ZStack 内
        // 的 VStack { HStack { Spacer; Button } Spacer } 那样把 Spacer 撑
        // 满全屏 → 拦了底部 ±10s 按钮的点击。
        .overlay(alignment: .topTrailing) {
            Button {
                store.minimize()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
        // 不要用 preferredColorScheme(.dark)：它会在 cover dismiss 后污染
        // 整个 app 的主题。本 view 已显式 Color.black 背景 + 白文字，无需
        // 覆盖系统配色。
        .onAppear {
            // Trainer痛点：训练中绝对不能锁屏。
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

/// Initial state — user tapped 「从 Watch 开始」 but no payload received yet
/// (站桩 30s 整理护具)。Shows reassuring "READY" so the trainer knows the
/// link is live and the system is waiting.
private struct ReadyOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("READY")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .tracking(2)
            Text("Apple Watch 已连接")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}

/// Set-active view — visible during reps. Per trainer R2: speed 96pt + Rep
/// 48pt (target bold) + VL% 32pt (smaller, sub to velocity).
@available(iOS 17.0, *)
private struct SetActiveView: View {
    let payload: LiveProgressPayload

    private var velocityColor: Color {
        // Color by current rep vs set best (peak). >=20% slower → red,
        // 10-20% → yellow, <10% → green/white.
        guard let v = payload.lastRepVelocity, let best = payload.setBestVelocity, best > 0 else {
            return .white
        }
        let dropPct = (best - v) / best * 100
        if dropPct >= 20 { return .red }
        if dropPct >= 10 { return .yellow }
        return .green
    }

    private var vlColor: Color {
        guard let vl = payload.vlPercent else { return .white }
        if vl >= 20 { return .red }
        if vl >= 10 { return .yellow }
        return .green
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top: exercise + weight + set index
            VStack(spacing: 4) {
                Text(payload.exerciseName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(Int(payload.targetWeightKg)) kg · 第 \(payload.setIndex + 1) 组")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.top, 60)

            Spacer()

            // Center: velocity 96pt + VL% 32pt
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(velocityText)
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .foregroundStyle(velocityColor)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .id(payload.currentRep)
                        .transition(.scale.combined(with: .opacity))
                    Text("m/s")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }

                if let vl = payload.vlPercent {
                    Text("VL \(Int(vl))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(vlColor)
                        .monospacedDigit()
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: payload.currentRep)

            Spacer()

            // Bottom: Rep counter — target数字加粗 white，已完成数 regular灰
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(payload.currentRep)")
                    .font(.system(size: 48, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Text(" / ")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.55))
                Text("\(payload.targetReps)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .monospacedDigit()
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var velocityText: String {
        guard let v = payload.lastRepVelocity else { return "—" }
        return String(format: "%.2f", v)
    }
}

/// Set-ended detail view — 4s horizontal bar chart of all reps. Auto
/// advances to the rest phase via Watch's `.restCountdown` push.
@available(iOS 17.0, *)
private struct SetEndedView: View {
    let payload: LiveProgressPayload

    private var avg: Double {
        guard !payload.repVelocities.isEmpty else { return 0 }
        return payload.repVelocities.reduce(0, +) / Double(payload.repVelocities.count)
    }

    private var best: Double { payload.repVelocities.max() ?? 0 }

    private func barColor(for v: Double) -> Color {
        guard best > 0 else { return .white }
        let dropPct = (best - v) / best * 100
        if dropPct >= 20 { return .red }
        if dropPct >= 10 { return .yellow }
        return .green
    }

    var body: some View {
        VStack(spacing: 28) {
            // Header summary
            VStack(spacing: 6) {
                Text("\(payload.repVelocities.count) reps")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("平均 \(String(format: "%.2f", avg)) · VL \(Int(payload.vlPercent ?? 0))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.top, 80)

            // Bar chart — horizontal, each rep as a column
            let maxBar: CGFloat = 180
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(payload.repVelocities.enumerated()), id: \.offset) { idx, v in
                    VStack(spacing: 4) {
                        Text(String(format: "%.2f", v))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .monospacedDigit()
                        Rectangle()
                            .fill(barColor(for: v))
                            .frame(width: 22, height: best > 0 ? maxBar * CGFloat(v / best) : 4)
                            .cornerRadius(3)
                        Text("\(idx + 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .monospacedDigit()
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Inter-set rest view per trainer R2: not pure black — minimal info layer.
/// Top: previous-set summary. Middle: big countdown. Bottom: next-set
/// preview + ±10s buttons + 详情 sheet.
@available(iOS 17.0, *)
private struct RestView: View {
    let payload: LiveProgressPayload
    @State private var showingDetails = false

    private var isFinal10s: Bool { (payload.restRemainingSec ?? 999) <= 10 }
    private var avg: Double {
        payload.repVelocities.isEmpty ? 0 : payload.repVelocities.reduce(0, +) / Double(payload.repVelocities.count)
    }

    var body: some View {
        ZStack {
            (isFinal10s ? Color.orange.opacity(0.18) : Color.black).ignoresSafeArea()
                .animation(.easeOut(duration: 0.3), value: isFinal10s)

            VStack(spacing: 0) {
                // Top bar: previous-set summary (tap details) + 跳过
                HStack(spacing: 10) {
                    Button { showingDetails = true } label: {
                        VStack(spacing: 2) {
                            Text("上组 \(payload.repVelocities.count) reps · VL \(Int(payload.vlPercent ?? 0))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text("平均 \(String(format: "%.2f", avg)) · 查看详情 →")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    Button {
                        TemplateSyncService.pushRestSkip(workoutId: payload.workoutId)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Text("跳过")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 60)
                .padding(.horizontal, 16)

                Spacer()

                // Middle: huge countdown
                Text(formatTime(payload.restRemainingSec ?? 0))
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundStyle(isFinal10s ? .orange : .white)
                    .monospacedDigit()

                // ±10s buttons flanking the next-set card
                HStack(spacing: 18) {
                    restAdjustButton(symbol: "−10s", delta: -10)
                    nextSetCard
                    restAdjustButton(symbol: "+10s", delta: +10)
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .sheet(isPresented: $showingDetails) {
            DetailsSheet(payload: payload)
        }
    }

    private var nextSetCard: some View {
        VStack(spacing: 4) {
            Text("下组")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(1.2)
            Text("\(Int(payload.targetWeightKg))kg × \(payload.targetReps)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1.5)
        )
    }

    private func restAdjustButton(symbol: String, delta: Int) -> some View {
        Button {
            TemplateSyncService.pushRestAdjust(deltaSeconds: delta, workoutId: payload.workoutId)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(symbol)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Color.white.opacity(0.12), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }
}

/// Drill-down 详情 sheet shown from RestView's top summary card.
/// V1: bar chart + VL%. V2 will add HR trace + per-rep MPV breakdown.
@available(iOS 17.0, *)
private struct DetailsSheet: View {
    let payload: LiveProgressPayload
    @Environment(\.dismiss) private var dismiss

    private var avg: Double {
        payload.repVelocities.isEmpty ? 0 : payload.repVelocities.reduce(0, +) / Double(payload.repVelocities.count)
    }
    private var best: Double { payload.repVelocities.max() ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header stats
                    HStack(spacing: 18) {
                        statBox(label: "Reps", value: "\(payload.repVelocities.count)")
                        statBox(label: "平均", value: String(format: "%.2f", avg), unit: "m/s")
                        statBox(label: "最快", value: String(format: "%.2f", best), unit: "m/s")
                        statBox(label: "VL", value: "\(Int(payload.vlPercent ?? 0))", unit: "%")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Divider().padding(.vertical, 4)

                    Text("本组速度曲线")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    barChart
                        .frame(height: 220)
                        .padding(.horizontal, 16)

                    Text("心率数据：训练完成后 Apple 健康同步可见")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }
            }
            .navigationTitle("本组详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func statBox(label: String, value: String, unit: String? = nil) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                if let unit {
                    Text(unit).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(payload.repVelocities.enumerated()), id: \.offset) { idx, v in
                VStack(spacing: 4) {
                    Text(String(format: "%.2f", v))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    GeometryReader { geo in
                        let frac = best > 0 ? CGFloat(v / best) : 0.05
                        VStack { Spacer() }
                            .frame(height: geo.size.height * frac)
                            .frame(maxWidth: .infinity)
                            .background(barColor(for: v), in: RoundedRectangle(cornerRadius: 4))
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    Text("\(idx + 1)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    private func barColor(for v: Double) -> Color {
        guard best > 0 else { return .gray }
        let dropPct = (best - v) / best * 100
        if dropPct >= 20 { return .red }
        if dropPct >= 10 { return .yellow }
        return .green
    }
}
