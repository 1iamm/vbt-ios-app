// WeeklyPlanView.swift
// VBTrainer · iPhone · 2026-05
//
// The "周计划" page accessed from the Plan tab. Shows the 7 days of the
// current ISO week, lets the user assign / change / clear a template per
// day, and (optionally) writes those entries to iPhone's Calendar via
// EventKit.

import SwiftUI
import SwiftData

struct WeeklyPlanView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @Query(sort: \DayPlan.date) private var allPlans: [DayPlan]

    @State private var anchorDate = Date()
    @State private var pickerDay: DayPickerSelection?
    @State private var calendarSyncEnabled = false

    struct DayPickerSelection: Identifiable {
        let id = UUID()
        let date: Date
    }

    private var goal: TrainingGoal { profiles.first?.trainingGoal ?? .strength }
    private var accent: Color { GoalTheme.accent(for: goal) }
    private var sysBlue: Color { Color(hex: "0A84FF") }

    private var weekStart: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: anchorDate)?.start
            ?? Calendar.current.startOfDay(for: anchorDate)
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var weekPlans: [Date: DayPlan] {
        let cal = Calendar.current
        var map: [Date: DayPlan] = [:]
        for plan in allPlans where weekDays.contains(where: { cal.isDate($0, inSameDayAs: plan.date) }) {
            map[cal.startOfDay(for: plan.date)] = plan
        }
        return map
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                weekHeader
                syncBanner
                daysList
                syncOptions
                disclaimer
                Spacer().frame(height: 24)
            }
        }
        .background(Tokens.Color.groupedBg.ignoresSafeArea())
        .navigationTitle("周计划")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pickerDay) { selection in
            NavigationStack {
                DayTemplatePickerSheet(day: selection.date, accent: accent)
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            calendarSyncEnabled = EventKitService.shared.isAuthorized
        }
    }

    private var weekHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekRangeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.4)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .textCase(.uppercase)
                let trainCount = weekDays.filter { weekPlans[Calendar.current.startOfDay(for: $0)] != nil }.count
                let restCount = 7 - trainCount
                Text("\(trainCount) 训 / \(restCount) 休")
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.5)
            }
            Spacer()
            HStack(spacing: 18) {
                Button {
                    if let d = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: anchorDate) {
                        anchorDate = d
                    }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold))
                }
                .tint(accent)
                Button {
                    if let d = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: anchorDate) {
                        anchorDate = d
                    }
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold))
                }
                .tint(accent)
            }
        }
        .padding(.horizontal, Tokens.Space.xl)
        .padding(.top, 12)
    }

    private var weekRangeLabel: String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M 月 d 日"
        let end = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let weekNo = cal.component(.weekOfYear, from: weekStart)
        return "\(f.string(from: weekStart)) — \(f.string(from: end)) · W\(weekNo)"
    }

    private var syncBanner: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                VStack(spacing: 0) {
                    Text("\(monthLabel)")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .tracking(0.4)
                    Text("\(dayLabel)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(calendarSyncEnabled ? "已同步到 iPhone 日历" : "同步到 iPhone 日历")
                    .font(.system(size: 14, weight: .semibold))
                Text(calendarSyncEnabled ? "「\(EventKitService.calendarName)」 · 改动实时同步" : "开启后会创建独立日历，避免污染日常")
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $calendarSyncEnabled)
                .labelsHidden()
                .tint(.green)
                .onChange(of: calendarSyncEnabled) { _, newValue in
                    if newValue {
                        Task {
                            // requestFullAccess（不是 writeOnly）— 后者
                            // 在 iOS 17+ 不能 enumerate calendars，导致
                            // upsert 找不到目标 calendar 静默失败。
                            let granted = await EventKitService.shared.requestFullAccess()
                            calendarSyncEnabled = granted
                            if granted { syncAllToCalendar() }
                        }
                    }
                }
        }
        .padding(12)
        .background(sysBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, Tokens.Space.lg)
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M月"
        return f.string(from: Date())
    }

    private var dayLabel: String {
        "\(Calendar.current.component(.day, from: Date()))"
    }

    private var daysList: some View {
        VStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                let plan = weekPlans[Calendar.current.startOfDay(for: day)]
                Button {
                    pickerDay = DayPickerSelection(date: day)
                } label: {
                    dayRow(day: day, plan: plan)
                }
                .buttonStyle(.plain)
                if day != weekDays.last {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func dayRow(day: Date, plan: DayPlan?) -> some View {
        let cal = Calendar.current
        let weekdayLabels = ["日","一","二","三","四","五","六"]
        let weekday = weekdayLabels[cal.component(.weekday, from: day) - 1]
        let template = plan.flatMap { p in templates.first(where: { $0.id == p.templateId }) }
        return HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("周\(weekday)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                Text("\(cal.component(.day, from: day))")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.3)
            }
            .frame(width: 34)

            if let plan, let template {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 4, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(-0.2)
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundStyle(sysBlue)
                        Text(plan.scheduledHHMM)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(sysBlue)
                        Text("·").foregroundStyle(Tokens.Color.tertiaryLabel)
                        Text("\(template.items.count) 个动作")
                            .font(.system(size: 12))
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            } else {
                let isToday = cal.isDate(day, inSameDayAs: Date())
                Text(isToday ? "+ 安排训练" : (isPast(day) ? "未训练" : "+ 安排训练"))
                    .font(.system(size: 13))
                    .foregroundStyle(isPast(day) && !isToday ? Tokens.Color.tertiaryLabel : accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Tokens.Color.separator, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private func isPast(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }

    @State private var reverseSyncEnabled = false

    private var syncOptions: some View {
        VStack(spacing: 0) {
            optionRow(icon: "tag", label: "写入到日历",
                      trailing: EventKitService.calendarName)
            Divider().padding(.leading, 44)
            optionRow(icon: "bell", label: "提前提醒", trailing: "30 分钟")
            Divider().padding(.leading, 44)
            optionRow(icon: "arrow.uturn.right", label: "循环", trailing: "每周")
            Divider().padding(.leading, 44)
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("反向读取")
                        .font(.system(size: 14))
                    Text("日历里改时间 / 删除事件 → 计划跟着变")
                        .font(.system(size: 10))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }
                Spacer()
                Toggle("", isOn: $reverseSyncEnabled)
                    .labelsHidden()
                    .tint(.green)
                    .onChange(of: reverseSyncEnabled) { _, newValue in
                        if newValue {
                            Task {
                                let granted = await EventKitService.shared.requestFullAccess()
                                reverseSyncEnabled = granted
                                if granted {
                                    DayPlanReverseSyncer.shared.runReconcile()
                                }
                            }
                        }
                    }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
        .onAppear {
            reverseSyncEnabled = EventKitService.shared.hasReadAccess
        }
    }

    private func optionRow(icon: String, label: String, trailing: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .frame(width: 20)
            Text(label).font(.system(size: 14))
            Spacer()
            Text(trailing)
                .font(.system(size: 13))
                .foregroundStyle(Tokens.Color.secondaryLabel)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private var disclaimer: some View {
        Text("编辑/删除任意一天的训练，iPhone 日历会在几秒内同步。开启循环后会按周生成事件。")
            .font(.system(size: 11))
            .foregroundStyle(Tokens.Color.tertiaryLabel)
            .padding(.horizontal, Tokens.Space.xl)
    }

    private func syncAllToCalendar() {
        for (day, plan) in weekPlans {
            guard let template = templates.first(where: { $0.id == plan.templateId }) else { continue }
            do {
                let id = try EventKitService.shared.upsert(
                    title: "训练 · \(template.name)",
                    date: day,
                    timeMinutes: plan.scheduledTimeMinutes,
                    notes: nil,
                    existingIdentifier: plan.eventKitIdentifier
                )
                plan.eventKitIdentifier = id
            } catch {
                #if DEBUG
                print("WeeklyPlanView sync error: \(error)")
                #endif
            }
        }
        try? context.save()
    }
}

struct DayTemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let day: Date
    let accent: Color

    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @Query(sort: \DayPlan.date) private var allPlans: [DayPlan]

    @State private var time: Date = {
        Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    }()

    private var existing: DayPlan? {
        let start = Calendar.current.startOfDay(for: day)
        return allPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: start) })
    }

    var body: some View {
        Form {
            Section("时间") {
                DatePicker("开练时间", selection: $time, displayedComponents: .hourAndMinute)
            }
            Section("选择模板") {
                if templates.isEmpty {
                    Text("没有模板，先到「计划」标签创建")
                        .font(.system(size: 13))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                }
                ForEach(templates) { tpl in
                    Button {
                        assign(tpl)
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accent).frame(width: 4, height: 28)
                            VStack(alignment: .leading) {
                                Text(tpl.name).foregroundStyle(Tokens.Color.label)
                                Text("\(tpl.items.count) 个动作")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Tokens.Color.secondaryLabel)
                            }
                            Spacer()
                            if existing?.templateId == tpl.id {
                                Image(systemName: "checkmark").foregroundStyle(accent)
                            }
                        }
                    }
                }
            }
            if existing != nil {
                Section {
                    Button(role: .destructive) {
                        DayPlanStore.unschedule(on: day, context: context)
                        if let id = existing?.eventKitIdentifier {
                            try? EventKitService.shared.delete(identifier: id)
                        }
                        dismiss()
                    } label: {
                        Text("清空当天安排").frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(formatDay(day))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let plan = existing {
                let comps = DateComponents(hour: plan.scheduledTimeMinutes / 60,
                                           minute: plan.scheduledTimeMinutes % 60)
                if let t = Calendar.current.date(from: comps) { time = t }
            }
        }
    }

    private func assign(_ template: Template) {
        let cal = Calendar.current
        let hh = cal.component(.hour, from: time)
        let mm = cal.component(.minute, from: time)
        let plan = DayPlanStore.schedule(
            templateId: template.id,
            on: day,
            timeMinutes: hh * 60 + mm,
            context: context
        )
        if EventKitService.shared.isAuthorized {
            do {
                let id = try EventKitService.shared.upsert(
                    title: "训练 · \(template.name)",
                    date: plan.date,
                    timeMinutes: plan.scheduledTimeMinutes,
                    notes: nil,
                    existingIdentifier: plan.eventKitIdentifier
                )
                plan.eventKitIdentifier = id
                try? context.save()
            } catch {
                #if DEBUG
                print("DayTemplatePicker EventKit error: \(error)")
                #endif
            }
        }
        let templateRef = template
        let date = plan.date
        Task { _ = await TemplateSyncService.pushAndStart(template: templateRef, on: date) }
        dismiss()
    }

    private func formatDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M 月 d 日 EEEE"
        return f.string(from: date)
    }
}

