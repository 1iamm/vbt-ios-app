// ExercisePickerSheet.swift
// VBTrainer · iPhone · 2026-05
//
// Reusable picker — used by PlanView ("添加动作") and any future entry that
// needs to choose from the static exercise library.

import SwiftUI

struct ExercisePickerSheet: View {
    var onPick: (Exercise) -> Void

    var body: some View {
        List {
            ForEach(ExerciseLookup.grouped, id: \.category) { group in
                Section(categoryName(group.category)) {
                    ForEach(group.items) { ex in
                        Button {
                            onPick(ex)
                        } label: {
                            HStack {
                                Image(systemName: ex.sfSymbol)
                                    .foregroundStyle(Tokens.Color.accent)
                                Text(ex.nameZH).foregroundStyle(Tokens.Color.label)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择动作")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func categoryName(_ c: ExerciseCategory) -> String {
        switch c {
        case .barbell: "杠铃"
        case .dumbbell: "哑铃"
        case .bodyweight: "自重"
        case .machine: "器械"
        case .jump: "跳跃"
        }
    }
}
