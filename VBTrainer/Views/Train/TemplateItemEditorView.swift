// TemplateItemEditorView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct TemplateItemEditorView: View {
    @Bindable var item: TemplateItem

    @State private var hasTargetWeight: Bool = false
    @State private var weight: Double = 80
    @State private var hasVelocityTarget: Bool = false
    @State private var velocityMin: Double = 0.5
    @State private var velocityMax: Double = 0.7

    private var exercise: Exercise? { ExerciseLookup.exercise(byId: item.exerciseId) }

    var body: some View {
        Form {
            Section {
                if let ex = exercise {
                    HStack {
                        Image(systemName: ex.sfSymbol)
                            .foregroundStyle(Tokens.Color.accent)
                        Text(ex.nameZH).font(Tokens.Font.headline)
                    }
                }
            }

            Section("目标") {
                Stepper("组数：\(item.targetSets)", value: $item.targetSets, in: 1...10)
                Stepper("Reps：\(item.targetReps)", value: $item.targetReps, in: 1...30)
                Toggle("设定目标重量", isOn: $hasTargetWeight)
                if hasTargetWeight {
                    HStack {
                        Text("重量")
                        Spacer()
                        TextField("kg", value: $weight, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }

            Section("速度区间（可选）") {
                Toggle("设定目标速度", isOn: $hasVelocityTarget)
                if hasVelocityTarget {
                    HStack {
                        Text("下限")
                        Spacer()
                        TextField("m/s", value: $velocityMin, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("上限")
                        Spacer()
                        TextField("m/s", value: $velocityMax, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }

            Section("VL% 警戒线") {
                HStack {
                    Text("VL ≤")
                    Spacer()
                    Stepper(value: Binding(
                        get: { Int(item.vlCeiling ?? 20) },
                        set: { item.vlCeiling = Double($0) }
                    ), in: 5...50, step: 5) {
                        Text("\(Int(item.vlCeiling ?? 20)) %")
                    }
                }
            }

            Section("组间休息") {
                Picker("休息时长", selection: $item.restSeconds) {
                    ForEach([30, 60, 90, 120, 180], id: \.self) { sec in
                        Text("\(sec) 秒").tag(sec)
                    }
                }
            }

            if exercise?.isUnilateral == true {
                Section("单边动作") {
                    Picker("起始一侧", selection: Binding(
                        get: { item.side },
                        set: { item.side = $0 }
                    )) {
                        Text("左").tag(Side.left)
                        Text("右").tag(Side.right)
                        Text("双侧").tag(Side.both)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .navigationTitle(exercise?.nameZH ?? "动作")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { syncFromItem() }
        .onDisappear { syncToItem() }
    }

    private func syncFromItem() {
        if let w = item.targetWeightKg {
            hasTargetWeight = true
            weight = w
        }
        if let lo = item.targetVelocityMin, let hi = item.targetVelocityMax {
            hasVelocityTarget = true
            velocityMin = lo
            velocityMax = hi
        }
    }

    private func syncToItem() {
        item.targetWeightKg = hasTargetWeight ? weight : nil
        item.targetVelocityMin = hasVelocityTarget ? velocityMin : nil
        item.targetVelocityMax = hasVelocityTarget ? velocityMax : nil
    }
}
