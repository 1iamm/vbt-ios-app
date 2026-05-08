// TemplateEditorView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let template: Template?
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var items: [TemplateItem] = []
    @State private var showingExercisePicker = false

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("模板名称", text: $name)
                TextField("备注（可选）", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("动作清单") {
                ForEach(items.sorted(by: { $0.index < $1.index })) { item in
                    NavigationLink {
                        TemplateItemEditorView(item: item)
                    } label: {
                        itemRow(item)
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)

                Button {
                    showingExercisePicker = true
                } label: {
                    Label("添加动作", systemImage: "plus.circle.fill")
                        .foregroundStyle(Tokens.Color.accent)
                }
            }

            if template != nil {
                Section {
                    Button(role: .destructive) {
                        if let t = template { context.delete(t) }
                        try? context.save()
                        dismiss()
                    } label: {
                        Text("删除模板").frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(template == nil ? "新建模板" : "编辑模板")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存", action: save)
                    .bold()
                    .disabled(name.isEmpty)
            }
        }
        .onAppear { loadIfNeeded() }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExercisePickerSheet { exercise in
                    addItem(for: exercise)
                    showingExercisePicker = false
                }
            }
        }
    }

    private func itemRow(_ item: TemplateItem) -> some View {
        let exName = ExerciseLookup.exercise(byId: item.exerciseId)?.nameZH ?? item.exerciseId
        return VStack(alignment: .leading, spacing: 2) {
            Text(exName).font(Tokens.Font.headline)
            Text("\(item.targetSets) 组 × \(item.targetReps) reps · \(item.targetWeightKg.map { String(format: "%.1f kg", $0) } ?? "无重量")")
                .font(Tokens.Font.footnote)
                .foregroundStyle(Tokens.Color.secondaryLabel)
        }
    }

    private func loadIfNeeded() {
        guard let t = template, name.isEmpty else { return }
        name = t.name
        notes = t.notes ?? ""
        items = t.items
    }

    private func deleteItems(at offsets: IndexSet) {
        let sorted = items.sorted(by: { $0.index < $1.index })
        for i in offsets {
            if let idx = items.firstIndex(where: { $0.id == sorted[i].id }) {
                context.delete(items[idx])
                items.remove(at: idx)
            }
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var sorted = items.sorted(by: { $0.index < $1.index })
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, item) in sorted.enumerated() {
            item.index = i + 1
        }
        items = sorted
    }

    private func addItem(for ex: Exercise) {
        let nextIndex = (items.map(\.index).max() ?? 0) + 1
        let item = TemplateItem(
            index: nextIndex,
            exerciseId: ex.id,
            targetSets: 3,
            targetReps: 5,
            targetWeightKg: nil,
            targetVelocityRange: ex.defaultTargetVelocityRange,
            vlCeiling: ex.defaultVLCeiling,
            restSeconds: 90,
            side: ex.isUnilateral ? .left : .both
        )
        context.insert(item)
        items.append(item)
    }

    private func save() {
        if let t = template {
            t.name = name
            t.notes = notes.isEmpty ? nil : notes
            t.updatedAt = Date()
            // Re-bind items
            for item in items {
                item.template = t
            }
            t.items = items
        } else {
            let t = Template(name: name, notes: notes.isEmpty ? nil : notes)
            for item in items { item.template = t }
            t.items = items
            context.insert(t)
        }
        try? context.save()
        dismiss()
    }
}

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
        case .barbell:    return "杠铃"
        case .dumbbell:   return "哑铃"
        case .bodyweight: return "自重"
        case .machine:    return "器械"
        case .jump:       return "跳跃"
        }
    }
}
