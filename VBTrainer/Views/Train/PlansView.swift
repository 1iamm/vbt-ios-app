// PlansView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI
import SwiftData

struct PlansView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    EmptyStateCard(
                        title: "还没有训练模板",
                        subtitle: "创建你的第一个模板，挂到日历上即可开始有计划地训练"
                    )
                    .padding(Tokens.Space.lg)
                } else {
                    List {
                        ForEach(templates) { tpl in
                            NavigationLink {
                                TemplateEditorView(template: tpl)
                            } label: {
                                templateRow(tpl)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("训练计划")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    TemplateEditorView(template: nil)
                }
            }
        }
    }

    private func templateRow(_ tpl: Template) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tpl.name)
                .font(Tokens.Font.headline)
            Text("\(tpl.items.count) 个动作")
                .font(Tokens.Font.footnote)
                .foregroundStyle(Tokens.Color.secondaryLabel)
        }
        .padding(.vertical, 4)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            context.delete(templates[i])
        }
        try? context.save()
    }
}
