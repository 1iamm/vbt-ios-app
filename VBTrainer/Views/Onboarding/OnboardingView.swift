// OnboardingView.swift
// VBTrainer · iPhone · 2026-05

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

    var body: some View {
        VStack {
            Spacer()
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Tokens.Space.xxl)
            Spacer()

            HStack(spacing: Tokens.Space.lg) {
                if step > 0 && step < 4 {
                    Button("返回") {
                        step -= 1
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                }
                Spacer()
                Button(action: advance) {
                    Text(step == 4 ? "开始使用" : "继续")
                        .font(Tokens.Font.headline)
                        .padding(.horizontal, Tokens.Space.xl)
                        .padding(.vertical, Tokens.Space.md)
                        .background(Tokens.Color.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Tokens.Space.xxl)
            .padding(.bottom, Tokens.Space.xxl)
        }
        .background(Tokens.Color.bg.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcomeStep
        case 1: HealthKitPermissionView()
        case 2: basicsStep
        case 3: backgroundStep
        case 4: completionStep
        default: EmptyView()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: Tokens.Space.xl) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 60))
                .foregroundStyle(Tokens.Color.accent)
            Text("用速度衡量你的训练")
                .font(Tokens.Font.largeTitle)
                .multilineTextAlignment(.center)
            Text("VBTrainer 通过 Apple Watch 在手腕上自动识别每一次 Rep，计算速度，监控心率，给你一个真实的训练数据回看。")
                .font(Tokens.Font.body)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private var basicsStep: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xl) {
            Text("基础信息")
                .font(Tokens.Font.title)

            HStack {
                Text("年龄").frame(width: 80, alignment: .leading)
                Stepper("\(age)", value: $age, in: 12...100)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            HStack {
                Text("性别").frame(width: 80, alignment: .leading)
                Picker("", selection: $sex) {
                    Text("男").tag(Sex.male)
                    Text("女").tag(Sex.female)
                    Text("其他").tag(Sex.other)
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Text("身高 (cm)").frame(width: 80, alignment: .leading)
                TextField("175", value: $height, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("体重 (kg)").frame(width: 80, alignment: .leading)
                TextField("70", value: $weight, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var backgroundStep: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xl) {
            Text("训练背景")
                .font(Tokens.Font.title)

            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                Text("体型")
                    .font(Tokens.Font.headline)
                Picker("", selection: $bodyType) {
                    Text("瘦").tag(BodyType.lean)
                    Text("标准").tag(BodyType.standard)
                    Text("偏壮").tag(BodyType.stocky)
                    Text("健美").tag(BodyType.muscular)
                    Text("力量型").tag(BodyType.powerlifter)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                Text("训练年限")
                    .font(Tokens.Font.headline)
                Picker("", selection: $experience) {
                    Text("< 1y").tag(TrainingExperience.lessThan1Year)
                    Text("1-3y").tag(TrainingExperience.oneToThree)
                    Text("3-5y").tag(TrainingExperience.threeToFive)
                    Text(">5y").tag(TrainingExperience.moreThan5Years)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                Text("训练目标")
                    .font(Tokens.Font.headline)
                Picker("", selection: $goal) {
                    Text("爆发").tag(TrainingGoal.power)
                    Text("力量").tag(TrainingGoal.strength)
                    Text("增肌").tag(TrainingGoal.muscle)
                    Text("减脂").tag(TrainingGoal.fatLoss)
                    Text("综合").tag(TrainingGoal.general)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var completionStep: some View {
        VStack(spacing: Tokens.Space.xl) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Tokens.Color.success)
            Text("一切就绪")
                .font(Tokens.Font.largeTitle)
            Text("点 \"开始使用\" 进入主界面，戴上你的 Apple Watch 开始训练。")
                .font(Tokens.Font.body)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private func advance() {
        if step == 4 {
            saveProfile()
            onCompleted()
        } else {
            step += 1
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
