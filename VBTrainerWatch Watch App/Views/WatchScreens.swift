// WatchScreens.swift
// VBTrainer · watchOS · 2026-05
//
// All 14 Watch screens, kept in a single file for V1 (low ceremony,
// each screen is < 80 lines). When V2 adds complexity, split per screen.

import SwiftUI

// MARK: - Shared style helpers

private let bg = Color.black
private let fg = Color.white
private let sub = Color.white.opacity(0.55)
private let accent = Tokens.Color.accent

private struct WatchScreenChrome<Content: View>: View {
    let title: String?
    let titleColor: Color
    @ViewBuilder var content: Content

    init(title: String? = nil, titleColor: Color = accent, @ViewBuilder content: () -> Content) {
        self.title = title
        self.titleColor = titleColor
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            bg.ignoresSafeArea()
            content
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Readiness (圆环风格)

struct WatchReadinessView: View {
    @EnvironmentObject var nav: WatchNavigation
    var score: Int = 72
    var hrv: Int = 48
    var rhr: Int = 58
    var sleepH: Double = 7.5

    private var ringColor: Color {
        switch score {
        case 80...:    return Tokens.Color.success
        case 60..<80:  return Tokens.Color.warning
        default:       return Tokens.Color.danger
        }
    }
    private var tierLabel: String {
        switch score {
        case 80...:    return "状态良好"
        case 60..<80:  return "保守训练"
        default:       return "建议休息"
        }
    }

    var body: some View {
        WatchScreenChrome(title: "今日准备度") {
            ScrollView {
                VStack(spacing: 8) {
                    Spacer().frame(height: 22)   // clears chrome title (~17pt)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 7)
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100.0)
                            .stroke(ringColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(score)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(fg)
                                .monospacedDigit()
                            Text(tierLabel)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(sub)
                        }
                    }
                    .frame(width: 110, height: 110)

                    HStack(spacing: 6) {
                        miniStat("HRV", value: "\(hrv)", unit: "ms")
                        miniStat("RHR", value: "\(rhr)", unit: "bpm")
                        miniStat("睡眠", value: String(format: "%.1f", sleepH), unit: "h")
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 10)
            }
        }
    }

    private func miniStat(_ label: String, value: String, unit: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(fg)
            HStack(spacing: 1) {
                Text(label).font(.system(size: 9)).foregroundStyle(sub)
                Text(unit).font(.system(size: 9)).foregroundStyle(sub.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Live Workout (核心)

struct WatchLiveWorkoutView: View {
    @EnvironmentObject var nav: WatchNavigation
    @EnvironmentObject var controller: LiveWorkoutController
    let exerciseId: String
    let weightKg: Double

    /// Set true before pushing to a child screen so .onDisappear doesn't
    /// cancel the still-active session (NavigationStack disappears the
    /// pushed-from view too).
    @State private var didPushToChild = false

    private var exercise: Exercise? { ExerciseLookup.exercise(byId: exerciseId) }
    private var velocityColor: Color {
        switch controller.metStatus {
        case .excellent:  return Tokens.Color.success
        case .met:        return fg
        case .borderline: return Tokens.Color.warning
        case .failed:     return Tokens.Color.danger
        }
    }

    /// Display modes — Crown rotates to switch.
    private enum DisplayMode: Int, CaseIterable {
        case velocity, vl, hr
    }
    @State private var mode: DisplayMode = .velocity

    private var stateLabel: String {
        switch controller.metStatus {
        case .excellent:  return "优秀"
        case .met:        return "达标"
        case .borderline: return "偏慢"
        case .failed:     return "未达标"
        }
    }

    private var totalReps: Int {
        let i = controller.plannedSetCursor
        if i < controller.plannedSpecs.count { return controller.plannedSpecs[i].reps }
        return 0
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top: exercise · weight  | state label
                HStack {
                    Text("\(exercise?.nameZH ?? "训练") · \(Int(weightKg))kg")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(sub)
                    Spacer()
                    Text(stateLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(velocityColor)
                        .tracking(0.4)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                Spacer().frame(height: 6)

                // Center: huge primary readout (mode-switched)
                centerReadout
                    .focusable(true)
                    .digitalCrownRotation(
                        Binding(
                            get: { Double(mode.rawValue) },
                            set: { mode = DisplayMode(rawValue: max(0, min(2, Int($0.rounded())))) ?? .velocity }
                        ),
                        from: 0, through: 2, by: 1, sensitivity: .low,
                        isContinuous: false, isHapticFeedbackEnabled: true
                    )

                Spacer()

                // Bottom row: REPS | heart
                HStack(spacing: 10) {
                    VStack(spacing: 0) {
                        Text("REPS")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(sub)
                            .tracking(0.5)
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("\(controller.rep)")
                                .font(.system(size: 21, weight: .heavy, design: .rounded))
                                .foregroundStyle(fg)
                                .monospacedDigit()
                            if totalReps > 0 {
                                Text("/\(totalReps)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(sub)
                                    .monospacedDigit()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: 22)
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Tokens.Color.Data.heartRate)
                        Text("\(controller.heartRate)")
                            .font(.system(size: 21, weight: .heavy, design: .rounded))
                            .foregroundStyle(fg)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 14)

                if let err = controller.errorMessage {
                    Text(err)
                        .font(.system(size: 9))
                        .foregroundStyle(Tokens.Color.danger)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }

                // Bottom red end-set button
                Button {
                    Task {
                        await controller.endSet()
                        didPushToChild = true
                        nav.push(.setResult)
                    }
                } label: {
                    Text("结束本组")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(Tokens.Color.danger.opacity(0.18), in: Capsule())
                        .foregroundStyle(Tokens.Color.danger)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 6)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // V2: SetReady is the single start point. We only fall back to
            // start here if the controller is somehow not running yet (e.g.
            // user reached LiveWorkout via a non-V2 path). The controller
            // also guards `if isRunning { return }` internally — this extra
            // check avoids racing the SetReady → push(.liveWorkout) ordering
            // that could otherwise re-enter MotionManager.start before the
            // first start's `isRunning = true` lands, throwing
            // MotionError.alreadyRunning.
            if !controller.isRunning {
                await controller.start(exerciseId: exerciseId, weightKg: weightKg)
            }
        }
        .onDisappear {
            if !didPushToChild {
                Task { await controller.cancel() }
            }
        }
    }

    @ViewBuilder
    private var centerReadout: some View {
        switch mode {
        case .velocity:
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(String(format: "%.2f", controller.velocity))
                    .font(.system(size: 65, weight: .heavy, design: .rounded))
                    .foregroundStyle(velocityColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: controller.velocity))
                Text("m/s")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(sub)
            }
            .padding(.horizontal, 6)
        case .vl:
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(Int(controller.vlPercent))")
                    .font(.system(size: 65, weight: .heavy, design: .rounded))
                    .foregroundStyle(velocityColor)
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(velocityColor)
            }
        case .hr:
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(controller.heartRate)")
                    .font(.system(size: 65, weight: .heavy, design: .rounded))
                    .foregroundStyle(Tokens.Color.danger)
                    .monospacedDigit()
                Text("bpm")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(sub)
            }
        }
    }
}

// MARK: - Rest

struct WatchRestView: View {
    @EnvironmentObject var nav: WatchNavigation
    @EnvironmentObject var controller: LiveWorkoutController
    @State private var totalSeconds: Int
    @State private var remaining: Int
    @State private var advanced = false

    init(secondsRemaining: Int) {
        let s = max(secondsRemaining, 1)
        _totalSeconds = State(initialValue: s)
        _remaining = State(initialValue: s)
    }

    private var progress: CGFloat {
        CGFloat(totalSeconds - remaining) / CGFloat(max(totalSeconds, 1))
    }

    private var nextExName: String {
        guard controller.nextPlannedParams != nil else { return "" }
        // currentTemplateItemId points at current item; preparePlanned was
        // already called so the next set is in the same exercise.
        return ExerciseLookup.exercise(byId: controller.currentExerciseId)?.nameZH ?? ""
    }

    var body: some View {
        WatchScreenChrome(title: "组间休息", titleColor: fg) {
            VStack(spacing: 6) {
                Spacer().frame(height: 18)
                HStack(alignment: .center, spacing: 6) {
                    plusMinusButton(symbol: "−", offset: -10)
                    countdownRing
                    plusMinusButton(symbol: "+", offset: 10)
                }
                .padding(.horizontal, 6)

                if let next = controller.nextPlannedParams, !nextExName.isEmpty {
                    nextSetCard(next: next)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                } else {
                    Spacer()
                    Text("最后一组完成 — 倒计时结束自动跳到完成屏")
                        .font(.system(size: 9))
                        .foregroundStyle(sub)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                Spacer(minLength: 6)
            }
            .onAppear { startCountdown() }
        }
    }

    private var countdownRing: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(formatTime(remaining))
                    .font(.system(size: 35, weight: .heavy, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(fg)
                    .monospacedDigit()
                Text("剩余 · \(totalSeconds)s")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(sub)
                    .tracking(0.4)
            }
        }
        .frame(width: 89, height: 89)
    }

    private func plusMinusButton(symbol: String, offset: Int) -> some View {
        Button {
            adjustRemaining(by: offset)
        } label: {
            VStack(spacing: 1) {
                Text(symbol)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(fg)
                Text("10s")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(sub)
            }
            .frame(width: 28, height: 28)
            .background(Color.white.opacity(0.08), in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func nextSetCard(next: (weightKg: Double, reps: Int, rest: Int, isWarmUp: Bool)) -> some View {
        let totalSets = max(controller.plannedSpecs.count, 1)
        let cursor = min(controller.plannedSetCursor + 1, totalSets)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("下一组")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(accent)
                    .tracking(0.5)
                Spacer()
                Text("\(cursor)/\(totalSets)")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(accent)
                    .monospacedDigit()
            }
            HStack(alignment: .firstTextBaseline) {
                Text(nextExName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .tracking(-0.4)
                    .foregroundStyle(fg)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(Int(next.weightKg))")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(fg)
                        .tracking(-0.5)
                        .monospacedDigit()
                    Text("kg")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(sub)
                    Text("×")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(sub)
                        .padding(.leading, 2)
                    Text("\(next.reps)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(fg)
                        .tracking(-0.5)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.orange.opacity(0.45), lineWidth: 1.2)
        )
    }

    private func adjustRemaining(by delta: Int) {
        let raw = remaining + delta
        remaining = max(5, min(600, raw))
        // Bump totalSeconds when adding so the ring doesn't visually jump.
        if delta > 0 { totalSeconds = max(totalSeconds, remaining) }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startCountdown() {
        Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if remaining > 0 { remaining -= 1 }
            }
            guard !advanced else { return }
            advanced = true
            HapticFeedback.restEnded()
            if controller.nextPlannedParams != nil {
                await controller.startNextSet()
                nav.replaceTop(with: .setReady)
            } else {
                nav.replaceTop(with: .workoutDone)
            }
        }
    }
}

// MARK: - Summary

struct WatchSummaryView: View {
    @EnvironmentObject var nav: WatchNavigation
    @EnvironmentObject var controller: LiveWorkoutController

    /// Subjective load 1–10 (Borg CR-10). Default 7 = "moderate-hard" — close
    /// to the actual mode for strength training, lets users single-tap accept
    /// without scrolling for typical sessions.
    @State private var rpe: Int = 7
    @State private var feeling: Feeling = .normal

    enum Feeling: String, CaseIterable {
        case strong = "强"
        case normal = "正常"
        case bad = "拉胯"

        var emoji: String {
            switch self {
            case .strong: return "💪"
            case .normal: return "·"
            case .bad:    return "😩"
            }
        }
    }

    var body: some View {
        WatchScreenChrome(title: "训练总结") {
            ScrollView {
                VStack(spacing: 10) {
                    Spacer().frame(height: 24)
                    HStack {
                        summaryStat("总Reps", "\(controller.totalReps)", color: fg)
                        summaryStat("平均速度", String(format: "%.2f", controller.avgVelocity), color: Tokens.Color.Data.velocity, unit: "m/s")
                    }
                    HStack {
                        summaryStat("VL%", "\(controller.avgVLPercent)", color: Tokens.Color.Data.velocityLoss, unit: "%")
                        summaryStat("心率", "\(controller.avgHeartRate)", color: Tokens.Color.Data.heartRate, unit: "bpm")
                    }

                    rpeSection

                    feelingSection

                    Button {
                        Task {
                            let notes = "感受：\(feeling.rawValue)"
                            let snap = await controller.completeWithFeedback(rpe: rpe, notes: notes)
                            WatchConnectivityService.shared.send(message: .workoutSnapshot(snap))
                            nav.popToRoot()
                        }
                    } label: {
                        Text("完成")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(accent, in: Capsule())
                            .foregroundStyle(fg)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var rpeSection: some View {
        VStack(spacing: 4) {
            Text("RPE")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(sub)
                .tracking(0.6)
            Text("\(rpe)")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(rpeColor)
                .focusable()
                .digitalCrownRotation(
                    Binding(get: { Double(rpe) },
                            set: { rpe = max(1, min(10, Int($0.rounded()))) }),
                    from: 1, through: 10, by: 1, sensitivity: .medium,
                    isContinuous: false, isHapticFeedbackEnabled: true
                )
            Text(rpeLabel)
                .font(.system(size: 10))
                .foregroundStyle(sub)
        }
        .padding(.vertical, 6)
    }

    private var rpeColor: Color {
        switch rpe {
        case 1...4:  return Tokens.Color.success
        case 5...7:  return fg
        case 8...9:  return Tokens.Color.warning
        default:     return Tokens.Color.danger
        }
    }

    private var rpeLabel: String {
        switch rpe {
        case 1: return "极轻"
        case 2: return "很轻"
        case 3: return "轻"
        case 4: return "略轻"
        case 5: return "中"
        case 6: return "略重"
        case 7: return "重"
        case 8: return "很重"
        case 9: return "极重"
        default: return "极限"
        }
    }

    private var feelingSection: some View {
        HStack(spacing: 6) {
            ForEach(Feeling.allCases, id: \.self) { f in
                Button { feeling = f } label: {
                    HStack(spacing: 3) {
                        Text(f.emoji).font(.system(size: 11))
                        Text(f.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(feeling == f ? fg : sub)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        feeling == f ? accent.opacity(0.25) : Color.white.opacity(0.06),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }

    private func summaryStat(_ label: String, _ value: String, color: Color, unit: String? = nil) -> some View {
        VStack(spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                if let unit { Text(unit).font(.system(size: 10)).foregroundStyle(sub) }
            }
            Text(label).font(.system(size: 10)).foregroundStyle(sub)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PR / VL / RPE

struct WatchPRCelebrationView: View {
    @EnvironmentObject var nav: WatchNavigation
    let title: String
    let value: String

    var body: some View {
        WatchScreenChrome(title: "新纪录", titleColor: accent) {
            ZStack {
                RadialGradient(
                    colors: [accent.opacity(0.18), .black],
                    center: .top, startRadius: 10, endRadius: 200
                )
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(accent)
                    Text("PR · 新纪录")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(value)
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(fg)
                    Text(title)
                        .font(.system(size: 14))
                        .foregroundStyle(sub)
                    Spacer()
                    Text("3s 自动消失")
                        .font(.system(size: 10))
                        .foregroundStyle(sub.opacity(0.6))
                        .padding(.bottom, 6)
                }
            }
        }
        .onAppear {
            HapticFeedback.notification()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                nav.pop()
            }
        }
    }
}

struct WatchVLStopWarningView: View {
    @EnvironmentObject var nav: WatchNavigation
    let vl: Double
    let threshold: Double

    var body: some View {
        WatchScreenChrome(title: "VL 警戒", titleColor: Tokens.Color.danger) {
            VStack(spacing: 4) {
                Spacer().frame(height: 22)
                Text("速度衰减超过阈值")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Tokens.Color.danger)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", vl))
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundStyle(Tokens.Color.danger)
                    Text("%").font(.system(size: 28, weight: .semibold)).foregroundStyle(Tokens.Color.danger)
                }
                Text("阈值 \(Int(threshold))% · 力量目标")
                    .font(.system(size: 11))
                    .foregroundStyle(sub)

                Spacer()
                HStack(spacing: 6) {
                    Button("继续") { nav.pop() }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.10), in: Capsule())
                        .foregroundStyle(fg)
                    Button("结束") { nav.push(.summary) }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Tokens.Color.danger, in: Capsule())
                        .foregroundStyle(fg)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
        .onAppear { HapticFeedback.vlCeilingExceeded() }
    }
}

struct WatchRPEInputView: View {
    @EnvironmentObject var nav: WatchNavigation
    @State private var rpe: Double = 8

    var body: some View {
        WatchScreenChrome(title: "本组主观感受") {
            VStack(spacing: 4) {
                Spacer().frame(height: 26)
                Text("RPE")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(sub)
                Text("\(Int(rpe))")
                    .font(.system(size: 90, weight: .heavy, design: .rounded))
                    .foregroundStyle(fg)
                    .focusable(true)
                    .digitalCrownRotation($rpe, from: 1, through: 10, by: 1, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: true)
                Text("Crown 调 · 1-10")
                    .font(.system(size: 10))
                    .foregroundStyle(sub.opacity(0.7))

                Spacer()
                Button("保存") { nav.pop() }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(accent, in: Capsule())
                    .foregroundStyle(fg)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }
        }
    }
}

// MARK: - V2 main flow (phone-driven · watch executes)

/// V2 root: phone-driven idle state. Shows iPhone glyph + cue copy. If a
/// today's plan already arrived via WatchConnectivity, surface a quick CTA.
struct SyncIdleView: View {
    @EnvironmentObject var nav: WatchNavigation
    @StateObject private var planStore = TodayPlanStore.shared

    var body: some View {
        WatchScreenChrome(title: "VBT", titleColor: sub) {
            VStack(spacing: 12) {
                Spacer().frame(height: 28)
                phoneGlyph
                Text("从手机开始")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(fg)
                Text("在 iPhone 选择动作或计划，\n手表自动加入并采集数据")
                    .font(.system(size: 10))
                    .foregroundStyle(sub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Spacer()
                if planStore.todayPlan != nil {
                    Button("查看已同步计划") { nav.push(.planSynced) }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(accent.opacity(0.25), in: Capsule())
                        .foregroundStyle(accent)
                        .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 14)
        }
    }

    /// Original 2-stroke iPhone-with-pulse glyph from the design canvas.
    private var phoneGlyph: some View {
        ZStack {
            // Phone outline 46×78
            RoundedRectangle(cornerRadius: 7)
                .stroke(sub, lineWidth: 1.2)
                .frame(width: 46, height: 78)
            RoundedRectangle(cornerRadius: 1.5)
                .stroke(sub.opacity(0.4), lineWidth: 0.8)
                .frame(width: 32, height: 58)
                .offset(y: -3)
            Circle()
                .fill(sub)
                .frame(width: 2.5, height: 2.5)
                .offset(y: 35)
            // Pulse waves
            Path { p in
                p.move(to: CGPoint(x: 27, y: -4))
                p.addQuadCurve(to: CGPoint(x: 27, y: 14), control: CGPoint(x: 33, y: 5))
            }
            .stroke(accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            .frame(width: 60, height: 60)
            .offset(x: 6, y: -2)
        }
        .frame(height: 80)
    }
}

/// V2 plan list grouped by exercise. Crown-scrollable; current set is highlighted.
struct PlanSyncedView: View {
    @EnvironmentObject var nav: WatchNavigation
    @EnvironmentObject var controller: LiveWorkoutController
    @StateObject private var planStore = TodayPlanStore.shared

    var body: some View {
        WatchScreenChrome(title: "已同步", titleColor: Tokens.Color.success) {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Spacer().frame(height: 22)
                    if let plan = planStore.todayPlan {
                        Text(plan.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(fg)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        Text("来自 iPhone · 转 Crown 滚动")
                            .font(.system(size: 8))
                            .foregroundStyle(sub.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)
                        ForEach(plan.items, id: \.id) { item in
                            itemSection(item: item)
                        }
                    } else {
                        Text("暂无计划")
                            .font(.system(size: 13))
                            .foregroundStyle(sub)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                    }
                    Text("在手机点击开始")
                        .font(.system(size: 8))
                        .foregroundStyle(sub.opacity(0.7))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    @ViewBuilder
    private func itemSection(item: TemplateItemSnapshot) -> some View {
        let exName = ExerciseLookup.exercise(byId: item.exerciseId)?.nameZH ?? item.exerciseId
        let specs = item.setSpecs.sorted { $0.index < $1.index }
        let totalSetCount = specs.count
        let isCurrentItem = controller.currentTemplateItemId == item.id
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(exName)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(fg)
                    .tracking(-0.2)
                Spacer()
                Text("休\(item.restSeconds)s · \(totalSetCount)组")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(sub)
                    .tracking(0.5)
                    .monospacedDigit()
            }
            .padding(.top, 4)
            ForEach(Array(specs.enumerated()), id: \.element.id) { (idx, spec) in
                let isCurrentSet = isCurrentItem && idx == controller.plannedSetCursor
                let isDoneSet = isCurrentItem && idx < controller.plannedSetCursor
                Button {
                    Task { @MainActor in
                        controller.preparePlanned(item: item)
                        nav.push(.setReady)
                    }
                } label: {
                    setRow(
                        idx: idx,
                        of: totalSetCount,
                        spec: spec,
                        isCurrent: isCurrentSet,
                        isDone: isDoneSet
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func setRow(idx: Int, of: Int, spec: TemplateSetSpecSnapshot,
                        isCurrent: Bool, isDone: Bool) -> some View {
        HStack(spacing: 6) {
            ZStack {
                if isCurrent {
                    Circle().fill(accent).frame(width: 5, height: 5)
                } else if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(sub)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 8)
            Text("\(idx + 1)/\(of)")
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(sub)
                .monospacedDigit()
                .frame(width: 22, alignment: .leading)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(Int(spec.weightKg))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isDone ? sub : fg)
                    .strikethrough(isDone, color: sub)
                Text("kg ")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(sub)
                Text("× \(spec.reps)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isDone ? sub : fg)
                    .strikethrough(isDone, color: sub)
            }
            .monospacedDigit()
        }
        .padding(.leading, 10)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            isCurrent ? accent.opacity(0.20) :
            (isDone ? Color.clear : Color.white.opacity(0.04)),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isCurrent ? accent : Color.clear, lineWidth: 1)
        )
        .opacity(isDone ? 0.55 : 1)
    }
}

/// V2 single-set warm-up — name + weight + start CTA.
struct SetReadyView: View {
    @EnvironmentObject var nav: WatchNavigation
    @EnvironmentObject var controller: LiveWorkoutController

    private var exerciseName: String {
        ExerciseLookup.exercise(byId: controller.currentExerciseId)?.nameZH ?? "训练"
    }

    private var setIndexLabel: String {
        let total = max(controller.plannedSpecs.count, 1)
        let idx = min(controller.plannedSetCursor + 1, total)
        return "第 \(idx) / \(total) 组"
    }

    private var targetReps: Int {
        let i = controller.plannedSetCursor
        if i < controller.plannedSpecs.count { return controller.plannedSpecs[i].reps }
        return 0
    }

    private var targetMV: String {
        if let r = controller.currentTargetRange {
            return String(format: "%.2f–%.2f", r.lowerBound, r.upperBound)
        }
        return "—"
    }

    @ViewBuilder
    private var sideChip: some View {
        switch controller.currentSide {
        case .both:
            EmptyView()
        case .left:
            Text("左侧")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.blue.opacity(0.18), in: Capsule())
        case .right:
            Text("右侧")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.blue.opacity(0.18), in: Capsule())
        }
    }

    var body: some View {
        WatchScreenChrome(title: setIndexLabel, titleColor: accent) {
            VStack(spacing: 6) {
                Spacer().frame(height: 26)
                HStack(spacing: 6) {
                    Text(exerciseName)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .tracking(-0.6)
                        .foregroundStyle(fg)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    sideChip
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(controller.currentWeightKg))")
                        .font(.system(size: 39, weight: .heavy, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(fg)
                        .monospacedDigit()
                    Text("kg")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(sub)
                }
                .padding(.top, 4)
                if targetReps > 0 {
                    Text("目标 \(targetReps) reps · MV \(targetMV) m/s")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(sub)
                        .padding(.top, 4)
                }
                Spacer()
                Button {
                    Task { @MainActor in
                        await controller.start(
                            exerciseId: controller.currentExerciseId,
                            weightKg: controller.currentWeightKg,
                            velocityVariant: controller.currentVelocityVariant,
                            targetRange: controller.currentTargetRange,
                            vlCeiling: controller.currentVLCeiling,
                            side: controller.currentSide,
                            defaultRestSeconds: controller.currentRestSeconds
                        )
                        nav.push(.liveWorkout(
                            exerciseId: controller.currentExerciseId,
                            weightKg: controller.currentWeightKg
                        ))
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("本组开始")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(accent, in: Capsule())
                    .foregroundStyle(fg)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
    }
}

/// V2 set-result — system-judged 3-state, auto-advance to Rest after 3s.
struct SetResultView: View {
    @EnvironmentObject var nav: WatchNavigation
    @EnvironmentObject var controller: LiveWorkoutController

    enum Outcome { case over, on, fail }

    private var outcome: Outcome {
        guard let summary = controller.lastSetMetSummary else { return .on }
        switch summary.status {
        case .excellent: return .over
        case .met, .borderline: return .on
        case .failed: return .fail
        }
    }

    private var color: Color {
        switch outcome {
        case .over: return Tokens.Color.success
        case .on:   return fg
        case .fail: return Tokens.Color.danger
        }
    }

    private var label: String {
        switch outcome {
        case .over: return "超过"
        case .on:   return "达标"
        case .fail: return "不达标"
        }
    }

    private var hint: String {
        switch outcome {
        case .over: return "速度高于目标区间"
        case .on:   return "速度落在目标区间"
        case .fail: return "速度低于目标区间"
        }
    }

    private var iconName: String {
        switch outcome {
        case .over: return "arrow.up"
        case .on:   return "checkmark"
        case .fail: return "arrow.down"
        }
    }

    private var bgColor: Color {
        switch outcome {
        case .over: return Tokens.Color.success.opacity(0.18)
        case .on:   return Color.white.opacity(0.12)
        case .fail: return Tokens.Color.danger.opacity(0.18)
        }
    }

    var body: some View {
        WatchScreenChrome(title: "本组结果", titleColor: color) {
            VStack(spacing: 4) {
                Spacer().frame(height: 22)
                ZStack {
                    Circle().fill(bgColor).frame(width: 38, height: 38)
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(color)
                    .padding(.top, 6)
                Text(hint)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(sub)
                Spacer()
                HStack(spacing: 4) {
                    statBox(label: "本组 MV", value: mvText, color: color)
                    statBox(label: "目标", value: targetText, color: fg)
                }
                .padding(.horizontal, 10)
                Text("3 秒后自动进入休息")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(sub.opacity(0.7))
                    .padding(.top, 6)
                    .padding(.bottom, 6)
            }
            .task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if controller.nextPlannedParams != nil {
                    nav.replaceTop(with: .rest(secondsRemaining: controller.currentRestSeconds))
                } else {
                    nav.replaceTop(with: .workoutDone)
                }
            }
        }
    }

    private var mvText: String {
        guard let mv = controller.lastSetMetSummary?.mv else { return "—" }
        return String(format: "%.2f", mv)
    }

    private var targetText: String {
        guard let r = controller.currentTargetRange else { return "—" }
        return String(format: "%.2f-%.2f", r.lowerBound, r.upperBound)
    }

    private func statBox(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(sub)
                .tracking(0.4)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
    }
}

/// V2 workout completion — 4-cell stat grid + sync CTA.
struct WorkoutDoneView: View {
    @EnvironmentObject var nav: WatchNavigation
    @EnvironmentObject var controller: LiveWorkoutController

    private var totalSets: Int { controller.completedSets.count }
    private var totalReps: Int { controller.totalReps }
    private var totalVolumeT: String {
        let kg = controller.completedSets.reduce(0.0) { acc, set in
            acc + (set.weightKg * Double(set.reps.count))
        }
        if kg >= 1000 { return String(format: "%.1f t", kg / 1000) }
        return "\(Int(kg)) kg"
    }
    private var durationStr: String {
        guard let first = controller.completedSets.first?.reps.first?.timestamp else { return "—" }
        let last = controller.completedSets.last?.reps.last?.timestamp ?? Date()
        let mins = Int(last.timeIntervalSince(first) / 60.0)
        return "\(max(mins, 1))′"
    }

    var body: some View {
        WatchScreenChrome(title: "训练完成", titleColor: Tokens.Color.success) {
            VStack(spacing: 8) {
                Spacer().frame(height: 22)
                ZStack {
                    Circle()
                        .stroke(Tokens.Color.success, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Tokens.Color.success)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6),
                                    GridItem(.flexible(), spacing: 6)],
                          spacing: 6) {
                    statCell(label: "总组数", value: "\(totalSets)")
                    statCell(label: "总 reps", value: "\(totalReps)")
                    statCell(label: "训练量", value: totalVolumeT)
                    statCell(label: "用时", value: durationStr)
                }
                .padding(.horizontal, 10)
                Spacer()
                Button {
                    Task { @MainActor in
                        let snap = await controller.completeWithFeedback(rpe: nil, notes: nil)
                        WatchConnectivityService.shared.send(message: .workoutSnapshot(snap))
                        nav.popToRoot()
                    }
                } label: {
                    Text("同步到 iPhone")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Tokens.Color.success.opacity(0.18), in: Capsule())
                        .foregroundStyle(Tokens.Color.success)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(sub)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(fg)
                .tracking(-0.5)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 7)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
