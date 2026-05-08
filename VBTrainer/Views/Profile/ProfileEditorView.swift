// ProfileEditorView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct ProfileEditorView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section("基础") {
                Stepper("年龄：\(profile.age)", value: $profile.age, in: 12...100)
                Picker("性别", selection: Binding(
                    get: { profile.sex },
                    set: { profile.sex = $0 }
                )) {
                    Text("男").tag(Sex.male)
                    Text("女").tag(Sex.female)
                    Text("其他").tag(Sex.other)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("身高")
                    Spacer()
                    TextField("cm", value: $profile.heightCm, format: .number.precision(.fractionLength(0)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("体重")
                    Spacer()
                    TextField("kg", value: $profile.weightKg, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section("训练背景") {
                Picker("体型", selection: Binding(
                    get: { profile.bodyType },
                    set: { profile.bodyType = $0 }
                )) {
                    Text("瘦").tag(BodyType.lean)
                    Text("标准").tag(BodyType.standard)
                    Text("偏壮").tag(BodyType.stocky)
                    Text("健美").tag(BodyType.muscular)
                    Text("力量型").tag(BodyType.powerlifter)
                }

                Picker("训练年限", selection: Binding(
                    get: { profile.trainingExperience },
                    set: { profile.trainingExperience = $0 }
                )) {
                    Text("< 1 年").tag(TrainingExperience.lessThan1Year)
                    Text("1-3 年").tag(TrainingExperience.oneToThree)
                    Text("3-5 年").tag(TrainingExperience.threeToFive)
                    Text("> 5 年").tag(TrainingExperience.moreThan5Years)
                }

                Picker("训练目标", selection: Binding(
                    get: { profile.trainingGoal },
                    set: { profile.trainingGoal = $0 }
                )) {
                    Text("爆发").tag(TrainingGoal.power)
                    Text("力量").tag(TrainingGoal.strength)
                    Text("增肌").tag(TrainingGoal.muscle)
                    Text("减脂").tag(TrainingGoal.fatLoss)
                    Text("综合").tag(TrainingGoal.general)
                }
            }

            Section("心率（可选）") {
                HStack {
                    Text("最大心率（实测）")
                    Spacer()
                    TextField("bpm（不填用 Tanaka 公式）",
                              value: $profile.measuredHRMax,
                              format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 140)
                }
                HStack {
                    Text("静息心率")
                    Spacer()
                    TextField("bpm（不填从 HealthKit 读）",
                              value: $profile.restingHR,
                              format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 160)
                }
            }
        }
        .navigationTitle("个人资料")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            profile.updatedAt = Date()
            try? context.save()
        }
    }
}
