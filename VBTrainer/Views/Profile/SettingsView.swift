// SettingsView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
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
                        PreferenceSyncService.push(.init(enableRepHaptic: newValue))
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
}
