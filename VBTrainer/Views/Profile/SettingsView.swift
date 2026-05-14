// SettingsView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    /// Mode preference is stored in UserDefaults (not on UserProfile because
    /// it can be device-local and shouldn't bloat the profile schema).
    @State private var trainingMode: TrainingModePreference = WorkoutModeResolver.preference

    var body: some View {
        Form {
            Section {
                Picker("训练模式", selection: $trainingMode) {
                    Text("自动").tag(TrainingModePreference.auto)
                    Text("仅 iPhone").tag(TrainingModePreference.forceIPhone)
                    Text("仅 Apple Watch").tag(TrainingModePreference.forceWatch)
                }
                .pickerStyle(.segmented)
                .onChange(of: trainingMode) { _, newValue in
                    WorkoutModeResolver.preference = newValue
                }
                Text(autoModeHint)
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            } header: {
                Text("训练模式")
            } footer: {
                Text("自动模式根据是否检测到 Apple Watch 决定走 Watch 实测还是 iPhone 手动记录。")
                    .font(Tokens.Font.footnote)
            }

            Section("单位") {
                Picker("重量", selection: Binding(
                    get: { profile.weightUnit },
                    set: { profile.weightUnit = $0 }
                )) {
                    Text("公斤 kg").tag(WeightUnit.kg)
                    Text("磅 lb").tag(WeightUnit.lb)
                }
                .pickerStyle(.segmented)
            }

            Section("训练偏好") {
                Picker("Crown 步进", selection: $profile.crownStep) {
                    Text("0.5 kg").tag(0.5)
                    Text("1 kg").tag(1.0)
                    Text("2.5 kg").tag(2.5)
                    Text("5 kg").tag(5.0)
                }
                Picker("默认组间休息", selection: $profile.defaultRestSeconds) {
                    ForEach([30, 60, 90, 120, 180], id: \.self) { sec in
                        Text("\(sec) 秒").tag(sec)
                    }
                }
                Toggle("Rep 完成震动", isOn: $profile.vibrationEnabled)
                    .onChange(of: profile.vibrationEnabled) { _, newValue in
                        TemplateSyncService.pushPreferences(.init(enableRepHaptic: newValue))
                    }
                Toggle("训练前 CMJ 测试提示", isOn: $profile.cmjOnEachWorkout)
            }

            Section {
                Text("每个动作的目标速度区间在「训练计划 → 编辑动作」中设置。")
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            } header: {
                Text("速度目标")
            }
        }
        .navigationTitle("训练设置")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            profile.updatedAt = Date()
            try? context.save()
        }
    }

    private var autoModeHint: String {
        switch trainingMode {
        case .auto: WorkoutModeResolver.autoResolutionLabel + " · 将\(WorkoutModeResolver.hasWatch ? "走 Watch 实测" : "走 iPhone 手动")"
        case .forceWatch: "强制走 Watch：需要佩戴 Apple Watch 才能开始训练"
        case .forceIPhone: "强制走 iPhone：手动输入每组重量和次数，不测速度"
        }
    }
}
