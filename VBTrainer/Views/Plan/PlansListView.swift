// PlansListView.swift
// VBTrainer · iPhone · 2026-05
//
// Top of the "计划" tab: list of all templates, plus an entry into the
// weekly planner. Replaces the old PlansView's NavigationLink → form-based
// editor with the new single-screen PlanView editor.

import SwiftUI
import SwiftData

struct PlansListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @State private var showingNew = false
    @State private var newTemplate: Template?

    private var goal: TrainingGoal { profiles.first?.trainingGoal ?? .strength }
    private var accent: Color { GoalTheme.accent(for: goal) }

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
                        .onTapGesture { createNew() }

                    if templates.isEmpty {
                        emptyView
                    } else {
                        VStack(spacing: 0) {
                            ForEach(templates) { tpl in
                                NavigationLink {
                                    PlanView(template: tpl, plannedDate: Date())
                                } label: {
                                    TemplateRowItem(template: tpl, accent: accent)
                                }
                                .buttonStyle(.plain)
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
                    Button { createNew() } label: { Image(systemName: "plus") }
                        .tint(accent)
                }
            }
            .navigationDestination(item: $newTemplate) { tpl in
                PlanView(template: tpl, plannedDate: Date())
            }
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

    private func createNew() {
        let tpl = Template(name: "新模板")
        context.insert(tpl)
        try? context.save()
        newTemplate = tpl
    }
}
