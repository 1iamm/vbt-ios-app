// PlansListView.swift
// VBTrainer · iPhone · 2026-05
//
// Top of the "计划" tab: list of all templates, plus an entry into the
// weekly planner. Replaces the old PlansView's NavigationLink → form-based
// editor with the new single-screen PlanView editor.

import SwiftData
import SwiftUI

struct PlansListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @State private var showingNew = false
    @State private var newTemplate: Template?
    @State private var creatingName: String = ""
    @State private var showingCreatePrompt = false
    @State private var renameTarget: Template?
    @State private var renameText: String = ""
    @State private var deleteTarget: Template?

    private var goal: TrainingGoal {
        profiles.first?.trainingGoal ?? .strength
    }

    private var accent: Color {
        GoalTheme.accent(for: goal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink {
                        WeeklyPlanView()
                    } label: {
                        weeklyEntryRow
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Tokens.Space.lg)
                    .padding(.top, 8)

                    SectionHeader(title: "我的模板", action: "+ 新建", accent: accent)
                        .onTapGesture { promptCreate() }

                    if templates.isEmpty {
                        emptyView
                    } else {
                        VStack(spacing: 0) {
                            ForEach(templates) { tpl in
                                templateRow(tpl)
                                if tpl.id != templates.last?.id {
                                    Divider().padding(.leading, 32)
                                }
                            }
                        }
                        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, Tokens.Space.lg)
                    }

                    Spacer().frame(height: 24)
                }
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())
            .navigationTitle("计划")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { promptCreate() } label: { Image(systemName: "plus") }
                        .tint(accent)
                }
            }
            .navigationDestination(item: $newTemplate) { tpl in
                PlanView(template: tpl, plannedDate: Date())
            }
            .alert("新建模板", isPresented: $showingCreatePrompt) {
                TextField("模板名称", text: $creatingName)
                    .textInputAutocapitalization(.never)
                Button("取消", role: .cancel) {
                    creatingName = ""
                }
                Button("创建") {
                    confirmCreate()
                }
                .disabled(trimmed(creatingName).isEmpty)
            } message: {
                Text("给模板起个名字，例如「推日」「腿日 A」")
            }
            .alert("重命名模板", isPresented: renameBinding) {
                TextField("模板名称", text: $renameText)
                    .textInputAutocapitalization(.never)
                Button("取消", role: .cancel) {
                    renameTarget = nil
                }
                Button("保存") {
                    confirmRename()
                }
                .disabled(trimmed(renameText).isEmpty)
            } message: {
                Text("名称不能为空。")
            }
            .alert("删除模板", isPresented: deleteBinding, presenting: deleteTarget) { tpl in
                Button("取消", role: .cancel) { deleteTarget = nil }
                Button("删除", role: .destructive) {
                    context.delete(tpl)
                    try? context.save()
                    deleteTarget = nil
                }
            } message: { tpl in
                Text("将永久删除「\(tpl.name)」。该操作不可恢复。")
            }
        }
    }

    private func templateRow(_ tpl: Template) -> some View {
        NavigationLink {
            PlanView(template: tpl, plannedDate: Date())
        } label: {
            TemplateRowItem(template: tpl, accent: accent)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteTarget = tpl
            } label: {
                Label("删除", systemImage: "trash")
            }
            Button {
                renameText = tpl.name
                renameTarget = tpl
            } label: {
                Label("重命名", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                renameText = tpl.name
                renameTarget = tpl
            } label: { Label("重命名", systemImage: "pencil") }
            Button(role: .destructive) {
                deleteTarget = tpl
            } label: { Label("删除模板", systemImage: "trash") }
        }
    }

    private var weeklyEntryRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("周计划")
                    .font(.system(size: 15, weight: .semibold))
                Text("一周 7 天 · 同步到 iPhone 日历")
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(14)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 28))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
            Text("还没有模板")
                .font(.system(size: 14, weight: .semibold))
            Text("创建一个，把动作和每组重量、次数、休息都规划好")
                .font(.system(size: 12))
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func promptCreate() {
        creatingName = ""
        showingCreatePrompt = true
    }

    private func confirmCreate() {
        let name = trimmed(creatingName)
        guard !name.isEmpty else { return }
        let tpl = Template(name: name)
        context.insert(tpl)
        try? context.save()
        creatingName = ""
        newTemplate = tpl
    }

    private func confirmRename() {
        guard let tpl = renameTarget else { return }
        let name = trimmed(renameText)
        guard !name.isEmpty else { return }
        tpl.name = name
        tpl.updatedAt = Date()
        try? context.save()
        renameTarget = nil
        renameText = ""
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var renameBinding: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { newValue in
                if !newValue {
                    renameTarget = nil
                    renameText = ""
                }
            }
        )
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { deleteTarget != nil },
            set: { newValue in if !newValue { deleteTarget = nil } }
        )
    }
}
