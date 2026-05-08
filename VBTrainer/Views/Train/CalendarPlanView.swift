// CalendarPlanView.swift
// VBTrainer · iPhone · 2026-05
//
// Lightweight month grid: pick a day → assign a template. Day→template
// mapping is stored as JSON in @AppStorage. Full plan execution lives
// in Proposal 9.

import SwiftUI
import SwiftData

struct CalendarPlanView: View {
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]

    @AppStorage("vbt.dayPlanMap") private var dayPlanMapJSON: String = "{}"

    @State private var selectedDay: Date?
    @State private var showingPicker = false

    private var dayMap: [String: String] {
        get {
            guard let data = dayPlanMapJSON.data(using: .utf8) else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

        VStack(alignment: .leading, spacing: Tokens.Space.lg) {
            Text(monthLabel(firstOfMonth))
                .font(Tokens.Font.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(["日","一","二","三","四","五","六"], id: \.self) { d in
                    Text(d)
                        .font(Tokens.Font.caption)
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }

                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) ?? firstOfMonth
                    dayCell(date: date, today: today)
                }
            }
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
        .sheet(isPresented: $showingPicker) {
            templatePickerSheet
        }
    }

    private func dayCell(date: Date, today: Date) -> some View {
        let key = Self.dayKeyFormatter.string(from: date)
        let hasTemplate = dayMap[key] != nil
        let isToday = Calendar.current.isDate(date, inSameDayAs: today)

        return Button {
            selectedDay = date
            showingPicker = true
        } label: {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundStyle(isToday ? Tokens.Color.accent : Tokens.Color.label)
                Circle()
                    .fill(hasTemplate ? Tokens.Color.accent : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hasTemplate ? Tokens.Color.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var templatePickerSheet: some View {
        if let day = selectedDay {
            NavigationStack {
                List {
                    Section {
                        Button("不安排训练（清空）", role: .destructive) {
                            assign(template: nil, on: day)
                        }
                    }
                    Section("选择模板") {
                        ForEach(templates) { t in
                            Button {
                                assign(template: t, on: day)
                            } label: {
                                HStack {
                                    Text(t.name).foregroundStyle(Tokens.Color.label)
                                    Spacer()
                                    Text("\(t.items.count) 动作")
                                        .font(Tokens.Font.footnote)
                                        .foregroundStyle(Tokens.Color.secondaryLabel)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(monthDayLabel(day))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { showingPicker = false }
                    }
                }
            }
        }
    }

    private func assign(template: Template?, on day: Date) {
        var map = dayMap
        let key = Self.dayKeyFormatter.string(from: day)
        if let t = template { map[key] = t.id.uuidString }
        else { map.removeValue(forKey: key) }
        if let data = try? JSONEncoder().encode(map),
           let str = String(data: data, encoding: .utf8) {
            dayPlanMapJSON = str
        }
        if let t = template {
            TemplateSyncService.push(template: t, on: day)
        }
        showingPicker = false
    }

    private func monthLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "yyyy 年 M 月"
        return f.string(from: date)
    }

    private func monthDayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M 月 d 日"
        return f.string(from: date)
    }
}
