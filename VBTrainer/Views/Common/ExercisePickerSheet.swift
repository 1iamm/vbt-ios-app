// ExercisePickerSheet.swift
// VBTrainer · iPhone · 2026-05
//
// Reusable picker — used by PlanView ("添加动作") and any future entry that
// needs to choose from the static exercise library.

import SwiftUI

struct ExercisePickerSheet: View {
    var onPick: (Exercise) -> Void

    @State private var query: String = ""

    var body: some View {
        List {
            ForEach(filteredGroups, id: \.category) { group in
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
            if filteredGroups.isEmpty {
                Section {
                    Text("无匹配动作")
                        .font(.system(size: 13))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("选择动作")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索动作（中文 / 英文）")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }

    /// 中文按子串包含；英文按大小写不敏感子串包含；id（kebab-case）也参与匹配。
    /// 支持「精准」（完整名）与「模糊」（任意子串）。
    private var filteredGroups: [(category: ExerciseCategory, items: [Exercise])] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return ExerciseLookup.grouped }
        let qLower = q.lowercased()
        return ExerciseLookup.grouped.compactMap { group in
            let items = group.items.filter { ex in
                ex.nameZH.contains(q)
                    || ex.nameEN.lowercased().contains(qLower)
                    || ex.id.lowercased().contains(qLower)
            }
            return items.isEmpty ? nil : (category: group.category, items: items)
        }
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
