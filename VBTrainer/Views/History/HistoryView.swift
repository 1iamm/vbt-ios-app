// HistoryView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 redesign: iOS-native calendar month + selected-day preview + month list.
// Supports list / exercise grouping segments. Done = accent dot, planned =
// blue dot, CMJ = velocity-blue dot. Today = system-red filled circle.

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \JumpTest.performedAt, order: .reverse) private var jumps: [JumpTest]
    @Query(sort: \DayPlan.date, order: .reverse) private var allPlans: [DayPlan]
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]

    @State private var month = Date()
    @State private var selected = Date()
    @State private var section: ListSection = .calendar

    enum ListSection: String, CaseIterable {
        case calendar = "日历"
        case list = "列表"
        case exercise = "动作"
    }

    private var goal: TrainingGoal { profiles.first?.trainingGoal ?? .strength }
    private var accent: Color { GoalTheme.accent(for: goal) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Picker("视图", selection: $section) {
                        ForEach(ListSection.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Tokens.Space.lg)
                    .padding(.vertical, 8)

                    syncBanner

                    switch section {
                    case .calendar:
                        IOSCalendarMonth(
                            month: $month,
                            selected: $selected,
                            markers: dotMarkers(),
                            onTap: { selected = $0 }
                        )
                        .padding(.horizontal, Tokens.Space.lg)
                        legend
                        selectedDayCard
                    case .list:
                        listView
                    case .exercise:
                        exerciseGroupsView
                    }

                    monthWorkoutsList

                    Spacer().frame(height: 24)
                }
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())
            .navigationTitle("历史")
        }
    }

    private var syncBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "0A84FF"))
            Text(EventKitService.shared.isAuthorized
                 ? "已与 iPhone 日历「\(EventKitService.calendarName)」联动"
                 : "未联动 iPhone 日历")
                .font(.system(size: 11))
                .foregroundStyle(Tokens.Color.secondaryLabel)
            Spacer()
            NavigationLink {
                WeeklyPlanView()
            } label: {
                Text("设置")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "0A84FF"))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color(hex: "0A84FF").opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.bottom, 10)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendDot(color: accent, label: "已练")
            legendDot(color: Tokens.Color.Data.velocity, label: "CMJ")
            legendDot(color: Color(hex: "0A84FF"), label: "已计划")
            Spacer()
        }
        .font(.system(size: 11))
        .foregroundStyle(Tokens.Color.secondaryLabel)
        .padding(.horizontal, Tokens.Space.lg + 4)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .overlay(alignment: .top) {
            Divider().padding(.horizontal, Tokens.Space.lg)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }

    private func dotMarkers() -> [Date: [IOSCalendarMonth.CalendarDot]] {
        let cal = Calendar.current
        var out: [Date: [IOSCalendarMonth.CalendarDot]] = [:]
        for w in workouts {
            let key = cal.startOfDay(for: w.startedAt)
            out[key, default: []].append(.done(accent))
        }
        for j in jumps {
            let key = cal.startOfDay(for: j.performedAt)
            out[key, default: []].append(.cmj)
        }
        // Plans render a 已计划 dot only when scheduled / inProgress and the
        // day doesn't already carry a completed-workout dot. Skipped / missed
        // plans get no calendar dot — they're surfaced in the list views.
        for plan in allPlans
            where plan.status == .scheduled || plan.status == .inProgress {
            let key = cal.startOfDay(for: plan.date)
            if !out.keys.contains(key) {
                out[key, default: []].append(.planned)
            }
        }
        return out
    }

    @ViewBuilder
    private var selectedDayCard: some View {
        let day = Calendar.current.startOfDay(for: selected)
        let dayWorkouts = workouts.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: day) }
        let plan = allPlans.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
        if let workout = dayWorkouts.first {
            SectionHeader(title: formatDay(day))
            NavigationLink {
                WorkoutDetailView(workoutId: workout.id)
            } label: {
                workoutSummaryCard(workout: workout)
            }
            .buttonStyle(.plain)
        } else if let plan, let template = templates.first(where: { $0.id == plan.templateId }) {
            SectionHeader(title: formatDay(day))
            plannedDayCard(plan: plan, template: template)
        } else {
            EmptyView()
        }
    }

    private func workoutSummaryCard(workout: Workout) -> some View {
        let exerciseName = ExerciseLookup.exercise(byId: workout.exerciseId)?.nameZH ?? workout.exerciseId
        let dur = Int(workout.durationSeconds / 60)
        let vol = workout.totalVolumeKg
        let setCount = workout.sets.count
        let avgVel = workout.sets.flatMap(\.reps).map(\.meanVelocity)
        let avgVelocity = avgVel.isEmpty ? 0 : avgVel.reduce(0, +) / Double(avgVel.count)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 4, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exerciseName)
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(-0.3)
                    Text("\(workout.sets.count) 个动作 · 已完成")
                        .font(.system(size: 11))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            HStack(spacing: 8) {
                miniStat(value: "\(dur)", label: "时长", unit: "分钟")
                miniStat(value: vol >= 1000 ? String(format: "%.1f", vol / 1000) : String(format: "%.0f", vol),
                         label: "总训练量",
                         unit: vol >= 1000 ? "t" : "kg")
                miniStat(value: "\(setCount)", label: "总组数", unit: nil)
                miniStat(value: String(format: "%.2f", avgVelocity), label: "均速", unit: "m/s")
            }
        }
        .padding(14)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func plannedDayCard(plan: DayPlan, template: Template) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "0A84FF"))
                .frame(width: 4, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                Text("\(plan.scheduledHHMM) · 计划中")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "0A84FF"))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func miniStat(value: String, label: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.3)
                if let unit {
                    Text(unit)
                        .font(.system(size: 9))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Tokens.Color.fill, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var monthWorkoutsList: some View {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
        let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        let monthWorkouts = workouts.filter { $0.startedAt >= monthStart && $0.startedAt < nextMonth }
        if !monthWorkouts.isEmpty {
            SectionHeader(title: "本月训练")
            VStack(spacing: 0) {
                ForEach(monthWorkouts) { w in
                    NavigationLink {
                        WorkoutDetailView(workoutId: w.id)
                    } label: {
                        workoutRow(w)
                    }
                    .buttonStyle(.plain)
                    if w.id != monthWorkouts.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Tokens.Space.lg)
        }
    }

    private func workoutRow(_ w: Workout) -> some View {
        let exerciseName = ExerciseLookup.exercise(byId: w.exerciseId)?.nameZH ?? w.exerciseId
        let dur = Int(w.durationSeconds / 60)
        let vol = w.totalVolumeKg
        let cal = Calendar.current
        let weekdayLabels = ["日","一","二","三","四","五","六"]
        let weekday = weekdayLabels[cal.component(.weekday, from: w.startedAt) - 1]
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(w.startedAt))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.3)
                Text("周\(weekday)")
                    .font(.system(size: 10))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            .frame(width: 36, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseName)
                    .font(.system(size: 15, weight: .semibold))
                Text("\(dur)m · \(vol >= 1000 ? String(format: "%.1ft", vol / 1000) : String(format: "%.0fkg", vol))")
                    .font(.system(size: 12))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    @ViewBuilder
    private var listView: some View {
        if workouts.isEmpty {
            EmptyStateCard(title: "还没有训练记录",
                           subtitle: "在 Watch 上完成第一次训练后，记录会自动同步到这里")
                .padding(.horizontal, Tokens.Space.lg)
                .padding(.top, 16)
        } else {
            VStack(spacing: 0) {
                ForEach(workouts) { w in
                    NavigationLink {
                        WorkoutDetailView(workoutId: w.id)
                    } label: {
                        workoutRow(w)
                    }
                    .buttonStyle(.plain)
                    if w.id != workouts.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var exerciseGroupsView: some View {
        let groups = Dictionary(grouping: workouts) { $0.exerciseId }
            .map { (id, ws) in (id, ws.sorted(by: { $0.startedAt > $1.startedAt })) }
            .sorted { $0.1.count > $1.1.count }
        VStack(spacing: 0) {
            ForEach(groups, id: \.0) { id, ws in
                NavigationLink {
                    WorkoutDetailView(workoutId: ws.first?.id ?? UUID())
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: ExerciseLookup.exercise(byId: id)?.sfSymbol ?? "dumbbell.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(accent)
                            .frame(width: 28)
                        Text(ExerciseLookup.exercise(byId: id)?.nameZH ?? id)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("\(ws.count)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Tokens.Color.tertiaryLabel)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Tokens.Color.tertiaryLabel)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                if id != groups.last?.0 {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.top, 8)
    }

    private func formatDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M 月 d 日 EEEE"
        return f.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M·d"
        return f.string(from: date)
    }
}
