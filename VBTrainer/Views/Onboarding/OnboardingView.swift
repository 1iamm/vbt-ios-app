// OnboardingView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 visual refresh — 4 steps matching the design canvas (vbt-screens v4):
//   1. 欢迎 (welcome hero)
//   2. 价值主张 (3 value bullets)
//   3. HealthKit 授权 (system prompt)
//   4. 个人画像 (basics + training background combined)
//
// Visual language:
//   - Top dots progress indicator
//   - Hero typography (96pt mono, accent color)
//   - Capsule accent CTA, monospaced numerics
//   - Tap card / segmented controls

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var step: Int = 0

    @State private var age: Int = 25
    @State private var sex: Sex = .male
    @State private var height: Double = 175
    @State private var weight: Double = 70
    @State private var bodyType: BodyType = .standard
    @State private var experience: TrainingExperience = .oneToThree
    @State private var goal: TrainingGoal = .strength

    var onCompleted: () -> Void

    // Under UI test we collapse the HealthKit step (index 2) so the
    // total is 3 (welcome / valueProp / profile). See `content`.
    private var totalSteps: Int { ProcessInfo.isUITestMode ? 3 : 4 }
    private var accent: Color { GoalTheme.accent(for: goal) }

    var body: some View {
        VStack(spacing: 0) {
            progressDots
                .padding(.top, 16)
                .padding(.bottom, 8)
                .accessibilityIdentifier("onboarding.progress")

            content
                .accessibilityIdentifier("onboarding.step.\(step)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            footerCTA
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Tokens.Color.bg.ignoresSafeArea())
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? accent : Tokens.Color.fill)
                    .frame(width: i == step ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcomeStep
        case 1: valuePropStep
        // Under UI tests we skip HealthKitPermissionView entirely — the
        // permission system sheet halts the runner. profileStep takes
        // its place at index 2 so `step == totalSteps - 1` math still
        // works (totalSteps becomes 3 below).
        case 2:
            if ProcessInfo.isUITestMode {
                profileStep
            } else {
                HealthKitPermissionView()
            }
        case 3: profileStep
        default: EmptyView()
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(maxHeight: 60)
            Text("01 · WELCOME")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(accent)
                .textCase(.uppercase)
                .padding(.bottom, 8)
            Text("用速度\n衡量训练")
                .font(.system(size: 44, weight: .bold))
                .tracking(-1)
                .lineSpacing(-2)
                .padding(.bottom, 16)
            Text("VBTrainer 通过 Apple Watch 在手腕上自动识别每一次 Rep，计算速度，监控心率，给你一个真实的训练数据回看。")
                .font(.system(size: 15))
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .lineSpacing(4)
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [accent.opacity(0.7), accent.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity)
            Spacer().frame(maxHeight: 60)
        }
    }

    private var valuePropStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(maxHeight: 40)
            Text("02 · WHY VBT")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(accent)
                .textCase(.uppercase)
                .padding(.bottom, 8)
            Text("速度比重量\n更诚实")
                .font(.system(size: 36, weight: .bold))
                .tracking(-0.8)
                .lineSpacing(-2)
                .padding(.bottom, 24)

            VStack(spacing: 14) {
                valueRow(icon: "waveform.path.ecg",
                         title: "速度衰减不会骗人",
                         body: "VL% 反映你今天真正能用的力量，比 RPE 客观。")
                valueRow(icon: "applewatch",
                         title: "手腕自动识别",
                         body: "不用绑设备到杠铃 — Apple Watch 100Hz IMU 直接采集。")
                valueRow(icon: "calendar.badge.clock",
                         title: "复盘从计划开始",
                         body: "训练前规划 ≤ 2 屏；训完看综合时间轴；周计划同步 iPhone 日历。")
            }
            Spacer()
        }
    }

    private func valueRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.2)
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
    }

    private var profileStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("04 · PROFILE")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(accent)
                    .textCase(.uppercase)
                Text("个人画像")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.6)
                    .padding(.bottom, 4)

                fieldGroup(title: "基础") {
                    rowStepper(label: "年龄", value: $age, in: 12...100, suffix: "岁")
                    rowSegmented(label: "性别", selection: $sex, options: [
                        (.male, "男"), (.female, "女"), (.other, "其他")
                    ])
                    rowNumberField(label: "身高", value: $height, suffix: "cm")
                    rowNumberField(label: "体重", value: $weight, suffix: "kg", decimals: 1)
                }

                fieldGroup(title: "训练背景") {
                    rowSegmented(label: "体型", selection: $bodyType, options: [
                        (.lean, "瘦"), (.standard, "标准"), (.stocky, "偏壮"),
                        (.muscular, "健美"), (.powerlifter, "力量型")
                    ])
                    rowSegmented(label: "经验", selection: $experience, options: [
                        (.lessThan1Year, "<1y"), (.oneToThree, "1-3y"),
                        (.threeToFive, "3-5y"), (.moreThan5Years, ">5y")
                    ])
                    rowSegmented(label: "目标", selection: $goal, options: [
                        (.power, "爆发"), (.strength, "力量"),
                        (.muscle, "增肌"), (.fatLoss, "减脂"), (.general, "综合")
                    ])
                }

                Text("以后可以在「我的 → 个人资料」里调整。")
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .padding(.top, 4)
            }
            .padding(.top, 30)
            .padding(.bottom, 8)
        }
    }

    private func fieldGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .textCase(.uppercase)
                .padding(.bottom, 8)
            VStack(spacing: 0) { content() }
                .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func rowStepper(label: String, value: Binding<Int>, in range: ClosedRange<Int>, suffix: String) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(label).font(.system(size: 14))
                Spacer()
                Text("\(value.wrappedValue) \(suffix)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .overlay(alignment: .top) { Divider().padding(.horizontal, 14) }
    }

    private func rowSegmented<T: Hashable>(
        label: String,
        selection: Binding<T>,
        options: [(T, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 13))
            Picker("", selection: selection) {
                ForEach(options, id: \.0) { option in
                    Text(option.1).tag(option.0)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .overlay(alignment: .top) { Divider().padding(.horizontal, 14) }
    }

    private func rowNumberField(label: String, value: Binding<Double>, suffix: String, decimals: Int = 0) -> some View {
        HStack {
            Text(label).font(.system(size: 14))
            Spacer()
            TextField("", value: value, format: .number.precision(.fractionLength(decimals)))
                .keyboardType(decimals > 0 ? .decimalPad : .numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(width: 80)
            Text(suffix)
                .font(.system(size: 11))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .overlay(alignment: .top) { Divider().padding(.horizontal, 14) }
    }

    // MARK: - Footer

    private var footerCTA: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { step -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Tokens.Color.label)
                        .frame(width: 48, height: 48)
                        .background(Tokens.Color.fill, in: Circle())
                }
                .buttonStyle(.plain)
            }
            Button(action: advance) {
                Text(step == totalSteps - 1 ? "开始使用" : "继续")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(0.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: accent.opacity(0.5), radius: 12, x: 0, y: 6)
            }
            // a11y modifiers BEFORE buttonStyle — order matters. With
            // .buttonStyle(.plain) applied after, SwiftUI sometimes lands the
            // identifier on a child element XCUITest can't query via
            // `app.buttons[...]`. Also setting accessibilityLabel as a
            // fallback so the button can be found by visible text as well.
            .accessibilityLabel(step == totalSteps - 1 ? "开始使用" : "继续")
            .accessibilityIdentifier(step == totalSteps - 1 ? "onboarding.cta.finish" : "onboarding.cta.continue")
            .buttonStyle(.plain)
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.22)) {
            if step == totalSteps - 1 {
                saveProfile()
                onCompleted()
            } else {
                step += 1
            }
        }
    }

    private func saveProfile() {
        let profile = UserProfile(
            age: age,
            sex: sex,
            heightCm: height,
            weightKg: weight,
            bodyType: bodyType,
            trainingExperience: experience,
            trainingGoal: goal
        )
        context.insert(profile)
        try? context.save()
    }
}
