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

// MARK: - Home

struct WatchHomeView: View {
    @EnvironmentObject var nav: WatchNavigation
    @StateObject private var planStore = TodayPlanStore.shared

    var body: some View {
        WatchScreenChrome {
            VStack(spacing: 8) {
                Spacer().frame(height: 18)
                Text("VBTrainer")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)

                if let plan = planStore.todayPlan {
                    Button {
                        nav.push(.planProgress)
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("今日计划：\(plan.name)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(fg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(plan.items.count) 个动作")
                                .font(.system(size: 11))
                                .foregroundStyle(sub)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        .background(accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }

                Spacer()

                Button {
                    nav.push(.readiness)
                } label: {
                    Text("开始训练")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accent, in: Capsule())
                        .foregroundStyle(fg)
                }
                .buttonStyle(.plain)

                VStack(spacing: 2) {
                    Text("上次：深蹲 100kg · 5×4")
                        .font(.system(size: 12))
                        .foregroundStyle(sub)
                    Text("MV 0.62 · VL 18%")
                        .font(.system(size: 11))
                        .foregroundStyle(sub.opacity(0.7))
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 12)
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
            VStack(spacing: 6) {
                Spacer().frame(height: 26)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(fg)
                            .monospacedDigit()
                        Text(tierLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(sub)
                    }
                }
                .frame(width: 130, height: 130)

                HStack(spacing: 12) {
                    miniStat("HRV", value: "\(hrv)", unit: "ms")
                    miniStat("RHR", value: "\(rhr)", unit: "bpm")
                    miniStat("睡眠", value: String(format: "%.1f", sleepH), unit: "h")
                }
                .padding(.top, 4)

                Spacer()

                HStack(spacing: 8) {
                    Button("跳过") { nav.push(.exercisePicker) }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(sub)
                    Button("CMJ 测试") { nav.push(.cmjCountdown) }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(accent.opacity(0.25), in: Capsule())
                        .foregroundStyle(accent)
                }
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 10)
        }
    }

    private func miniStat(_ label: String, value: String, unit: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(fg)
            HStack(spacing: 1) {
                Text(label).font(.system(size: 9)).foregroundStyle(sub)
                Text(unit).font(.system(size: 9)).foregroundStyle(sub.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - CMJ flow

struct WatchCMJCountdownView: View {
    @EnvironmentObject var nav: WatchNavigation
    @State private var seconds = 3
    let attemptIndex: Int = 1

    var body: some View {
        WatchScreenChrome(title: "CMJ 测试 · \(attemptIndex)/3") {
            VStack {
                Spacer()
                Text("\(seconds)")
                    .font(.system(size: 130, weight: .heavy, design: .rounded))
                    .foregroundStyle(fg)
                    .monospacedDigit()
                Text("准备")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(sub)
                Spacer()
            }
            .onAppear { startCountdown() }
        }
    }

    private func startCountdown() {
        Task { @MainActor in
            for s in (0..<3).reversed() {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                seconds = s + 1
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            nav.push(.cmjGo)
        }
    }
}

struct WatchCMJGoView: View {
    @EnvironmentObject var nav: WatchNavigation

    var body: some View {
        WatchScreenChrome {
            ZStack {
                Color.black.ignoresSafeArea()
                Text("跳！")
                    .font(.system(size: 92, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
            }
            .onAppear {
                HapticFeedback.notification()
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    nav.push(.cmjResult(attempts: [28.0, 31.5, 29.0]))
                }
            }
        }
    }
}

struct WatchCMJResultView: View {
    @EnvironmentObject var nav: WatchNavigation
    let attempts: [Double]

    private var best: Double { attempts.max() ?? 0 }

    var body: some View {
        WatchScreenChrome(title: "CMJ 结果") {
            VStack(spacing: 4) {
                Spacer().frame(height: 24)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", best))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(fg)
                        .monospacedDigit()
                    Text("cm")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(sub)
                }
                Text("最佳尝试")
                    .font(.system(size: 12))
                    .foregroundStyle(sub)

                HStack(spacing: 8) {
                    ForEach(Array(attempts.enumerated()), id: \.offset) { (i, h) in
                        VStack(spacing: 1) {
                            Text(String(format: "%.0f", h))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(fg)
                            Text("尝试\(i+1)")
                                .font(.system(size: 9))
                                .foregroundStyle(sub.opacity(0.6))
                        }
                    }
                }
                .padding(.top, 4)

                Spacer()
                Button("继续") { nav.push(.exercisePicker) }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(accent, in: Capsule())
                    .foregroundStyle(fg)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Exercise picker

struct WatchExercisePickerView: View {
    @EnvironmentObject var nav: WatchNavigation

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(ExerciseLookup.grouped, id: \.category) { group in
                        Text(categoryName(group.category))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(sub)
                            .padding(.top, 8)
                        ForEach(group.items) { ex in
                            Button {
                                nav.push(.weightInput(exerciseId: ex.id))
                            } label: {
                                HStack {
                                    Image(systemName: ex.sfSymbol)
                                        .foregroundStyle(accent)
                                        .font(.system(size: 14))
                                    Text(ex.nameZH)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(fg)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
        }
        .navigationTitle("选动作")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func categoryName(_ c: ExerciseCategory) -> String {
        switch c {
        case .barbell:    return "杠铃"
        case .dumbbell:   return "哑铃"
        case .bodyweight: return "自重"
        case .machine:    return "器械"
        case .jump:       return "跳跃"
        }
    }
}

// MARK: - Weight input

struct WatchWeightInputView: View {
    @EnvironmentObject var nav: WatchNavigation
    let exerciseId: String
    @State private var weight: Double = 100.0
    @State private var step: Double = 2.5

    private var exercise: Exercise? { ExerciseLookup.exercise(byId: exerciseId) }

    var body: some View {
        WatchScreenChrome(title: exercise?.nameZH) {
            VStack(spacing: 6) {
                Spacer().frame(height: 24)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", weight))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(fg)
                        .monospacedDigit()
                    Text("kg")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(sub)
                }
                .focusable(true)
                .digitalCrownRotation(
                    $weight,
                    from: 0, through: 500,
                    by: step, sensitivity: .medium,
                    isContinuous: false, isHapticFeedbackEnabled: true
                )

                Text("Crown 调节 · 步进 \(String(format: "%.1f", step)) kg")
                    .font(.system(size: 11))
                    .foregroundStyle(sub.opacity(0.7))

                Spacer()

                Button {
                    nav.push(.liveWorkout(exerciseId: exerciseId, weightKg: weight))
                } label: {
                    Text("开始")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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

// MARK: - Live Workout (核心)

struct WatchLiveWorkoutView: View {
    @EnvironmentObject var nav: WatchNavigation
    let exerciseId: String
    let weightKg: Double

    @State private var rep: Int = 5
    @State private var velocity: Double = 0.62
    @State private var heartRate: Int = 142
    @State private var status: MetStatus = .met
    @State private var vlPercent: Double = 18.0

    private var exercise: Exercise? { ExerciseLookup.exercise(byId: exerciseId) }
    private var velocityColor: Color {
        switch status {
        case .excellent:  return Tokens.Color.success
        case .met:        return fg
        case .borderline: return Tokens.Color.warning
        case .failed:     return Tokens.Color.danger
        }
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top: exercise + weight
                HStack {
                    Text(exercise?.nameZH ?? "训练")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(fg)
                    Text("\(Int(weightKg)) kg")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(sub)
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Tokens.Color.Data.heartRate)
                        Text("\(heartRate)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(fg)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)

                Spacer()

                // Center: huge velocity
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", velocity))
                            .font(.system(size: 76, weight: .heavy, design: .rounded))
                            .foregroundStyle(velocityColor)
                            .monospacedDigit()
                            .contentTransition(.numericText(value: velocity))
                        Text("m/s")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(sub)
                    }
                    Text("Rep \(rep) · VL \(Int(vlPercent))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(sub)
                }

                Spacer()

                // Bottom: end button
                Button {
                    nav.push(.rest(secondsRemaining: 90))
                } label: {
                    Text("结束本组")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Tokens.Color.danger.opacity(0.25), in: Capsule())
                        .foregroundStyle(Tokens.Color.danger)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Rest

struct WatchRestView: View {
    @EnvironmentObject var nav: WatchNavigation
    let totalSeconds: Int
    @State private var remaining: Int

    init(secondsRemaining: Int) {
        self.totalSeconds = max(secondsRemaining, 1)
        _remaining = State(initialValue: secondsRemaining)
    }

    private var progress: CGFloat {
        CGFloat(totalSeconds - remaining) / CGFloat(totalSeconds)
    }

    var body: some View {
        WatchScreenChrome(title: "组间休息") {
            VStack(spacing: 6) {
                Spacer().frame(height: 24)
                ZStack {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(remaining)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(fg)
                        .monospacedDigit()
                }
                .frame(width: 110, height: 110)

                Text("上组：6 reps · MV 0.62 · VL 18%")
                    .font(.system(size: 11))
                    .foregroundStyle(sub)

                Text("建议下组：保持 100kg")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)

                Spacer()

                HStack(spacing: 6) {
                    Button("跳过") { nav.push(.summary) }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(sub)
                    Button("下一组") { nav.pop() }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(accent, in: Capsule())
                        .foregroundStyle(fg)
                }
                .padding(.bottom, 6)
            }
            .onAppear { startCountdown() }
        }
    }

    private func startCountdown() {
        Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if remaining > 0 { remaining -= 1 }
            }
            HapticFeedback.restEnded()
        }
    }
}

// MARK: - Summary

struct WatchSummaryView: View {
    @EnvironmentObject var nav: WatchNavigation
    var totalReps: Int = 18
    var avgVelocity: Double = 0.58
    var avgVL: Int = 18
    var avgHR: Int = 138

    var body: some View {
        WatchScreenChrome(title: "训练总结") {
            VStack(spacing: 10) {
                Spacer().frame(height: 30)
                HStack {
                    summaryStat("总Reps", "\(totalReps)", color: fg)
                    summaryStat("平均速度", String(format: "%.2f", avgVelocity), color: Tokens.Color.Data.velocity, unit: "m/s")
                }
                HStack {
                    summaryStat("VL%", "\(avgVL)", color: Tokens.Color.Data.velocityLoss, unit: "%")
                    summaryStat("心率", "\(avgHR)", color: Tokens.Color.Data.heartRate, unit: "bpm")
                }
                Spacer()
                Button {
                    nav.popToRoot()
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

// MARK: - Plan progress / next

struct WatchPlanProgressView: View {
    @EnvironmentObject var nav: WatchNavigation
    @StateObject private var planStore = TodayPlanStore.shared

    var body: some View {
        WatchScreenChrome(title: planStore.todayPlan?.name ?? "今日计划") {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer().frame(height: 24)

                    if let plan = planStore.todayPlan {
                        ForEach(plan.items, id: \.id) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .foregroundStyle(sub)
                                    .font(.system(size: 14))
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(ExerciseLookup.exercise(byId: item.exerciseId)?.nameZH ?? item.exerciseId)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(fg)
                                    Text("\(item.targetSets) × \(item.targetReps)\(item.targetWeightKg.map { " · \(Int($0))kg" } ?? "")")
                                        .font(.system(size: 10))
                                        .foregroundStyle(sub.opacity(0.7))
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("没有今日计划")
                            .font(.system(size: 13))
                            .foregroundStyle(sub)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 30)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct WatchPlanNextView: View {
    @EnvironmentObject var nav: WatchNavigation
    var step: Int = 2
    var total: Int = 4
    var nextExercise: String = "卧推"
    var weight: Int = 75
    var sets: Int = 4
    var reps: Int = 8

    var body: some View {
        WatchScreenChrome(title: "下一项 · \(step)/\(total)") {
            VStack(spacing: 4) {
                Spacer().frame(height: 30)
                Text("从计划")
                    .font(.system(size: 12))
                    .foregroundStyle(sub)
                Text(nextExercise)
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundStyle(fg)
                Text("\(weight) kg")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(fg)
                Text("\(sets) 组 × \(reps) reps")
                    .font(.system(size: 14))
                    .foregroundStyle(sub)

                Spacer()
                Button {
                    nav.push(.weightInput(exerciseId: "bench-press"))
                } label: {
                    Text("开始本动作")
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
