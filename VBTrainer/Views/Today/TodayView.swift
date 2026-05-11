// TodayView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 redesign: header with big "今天" + 96pt Readiness ring; if a DayPlan
// exists for today, show a highlighted "已安排今日" banner with "从 Watch
// 开始" CTA; otherwise show AI recommendations + my templates + quick-start.
//
// Tapping a template / recommendation opens the single-screen Plan editor
// (PlanView). "从 Watch 开始" pushes the template snapshot to Watch.

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \ReadinessSnapshot.date, order: .reverse) private var readinessSnaps: [ReadinessSnapshot]
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @Query(sort: \DayPlan.date, order: .reverse) private var allPlans: [DayPlan]

    @State private var hasRefreshed = false
    @State private var pendingPlanTemplate: Template?
    @State private var pendingWorkoutDetail: WorkoutDetailRoute?
    @State private var showingTweaks = false
    @State private var cmjPromptShown = false
    @State private var pendingCelebration: CelebrationCard.Kind?

    struct WorkoutDetailRoute: Identifiable, Hashable {
        let id: UUID
    }

    private var goal: TrainingGoal { profiles.first?.trainingGoal ?? .strength }
    private var accent: Color { GoalTheme.accent(for: goal) }

    private var todayPlan: DayPlan? {
        let today = Calendar.current.startOfDay(for: Date())
        return allPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
    }

    private var todayTemplate: Template? {
        guard let plan = todayPlan else { return nil }
        return templates.first(where: { $0.id == plan.templateId })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TodayHeader(snapshot: readinessSnaps.first, goalAccent: accent)

                    let weekly = WeeklyAdherenceCalculator.compute(context: context)
                    if weekly.planned > 0 {
                        weekStripCard(weekly: weekly)
                    }

                    if let plan = todayPlan, let template = todayTemplate {
                        SectionHeader(title: bannerSectionTitle(for: plan.status))
                        ScheduledTrainingCard(
                            templateName: template.name,
                            source: scheduledSource(plan: plan),
                            status: plan.status,
                            summary: completedSummary(for: plan),
                            onPrimary: { handlePrimary(plan: plan, template: template) },
                            onSecondary: { handleSecondary(plan: plan, template: template) },
                            accent: accent
                        )
                        .padding(.bottom, 12)
                    }

                    let recs = AIRecommendationEngine.recommendations(context: context)
                    if !recs.isEmpty {
                        SectionHeader(title: "AI 推荐", action: "为何推荐 →", accent: Color(hex: "7C5CFF"))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(recs) { rec in
                                    Button {
                                        applyRecommendation(rec)
                                    } label: {
                                        AIRecommendationCard(rec: rec)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Tokens.Space.lg)
                        }
                        .padding(.bottom, 8)
                    }

                    SectionHeader(title: "我的模板", action: "管理 →", accent: accent)
                    myTemplatesList

                    SectionHeader(title: "快速起点")
                    quickStartGrid

                    Spacer().frame(height: 24)
                }
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())
            .overlay(alignment: .topTrailing) {
                TweaksButton { showingTweaks = true }
                    .padding(.top, 4)
                    .padding(.trailing, 12)
            }
            .overlay(alignment: .top) {
                if let kind = pendingCelebration {
                    CelebrationCard(kind: kind, onDismiss: dismissCelebration, accent: accent)
                        .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .task {
                guard !hasRefreshed else { return }
                hasRefreshed = true
                await ReadinessRefresher.refresh(in: context.container)
            }
            .task {
                // Subscribe to DayPlan event bus and surface celebrations.
                for await event in DayPlanEventBus.shared.stream {
                    if case let .completed(_, workoutId) = event {
                        await MainActor.run {
                            if let kind = CelebrationResolver.resolve(
                                completedWorkoutId: workoutId, context: context) {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                                    pendingCelebration = kind
                                }
                                Task {
                                    try? await Task.sleep(nanoseconds: 6_000_000_000)
                                    await MainActor.run { dismissCelebration() }
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $pendingPlanTemplate) { tpl in
                PlanView(template: tpl, plannedDate: Date())
            }
            .navigationDestination(item: $pendingWorkoutDetail) { route in
                WorkoutDetailView(workoutId: route.id)
            }
            .sheet(isPresented: $showingTweaks) {
                if let profile = profiles.first {
                    TweaksQuickSwitcher(profile: profile)
                        .presentationDetents([.medium, .large])
                }
            }
            .alert("在 Apple Watch 上启动 CMJ", isPresented: $cmjPromptShown) {
                Button("好的") {}
            } message: {
                Text("CMJ 神经测试在 Watch 上完成（3 跳取最佳）。打开 Apple Watch 上的 VBTrainer 即可。")
            }
        }
    }

    /// Route an AI recommendation to its correct destination.
    private func applyRecommendation(_ rec: AIRecommendation) {
        Haptics.selection()
        switch rec.kind {
        case .deload:
            guard let baseId = rec.templateIdHint,
                  let base = templates.first(where: { $0.id == baseId }) else {
                // No reference template — fall back to creating a new blank.
                createNewTemplate()
                return
            }
            let tpl = RecommendationTemplateBuilder.buildDeload(baseTemplate: base, in: context)
            pendingPlanTemplate = tpl
        case .prRetest:
            guard let exId = rec.exerciseIdHint, let weight = rec.weightHint else {
                createNewTemplate()
                return
            }
            let tpl = RecommendationTemplateBuilder.buildPRRetest(
                exerciseId: exId, lastTopWeight: weight, in: context)
            pendingPlanTemplate = tpl
        case .cmjTest:
            cmjPromptShown = true
        }
    }

    private func createNewTemplate() {
        let tpl = Template(name: "新模板")
        context.insert(tpl)
        try? context.save()
        pendingPlanTemplate = tpl
    }

    @ViewBuilder
    private var myTemplatesList: some View {
        if templates.isEmpty {
            VStack(spacing: 8) {
                Text("还没有模板")
                    .font(.system(size: 14, weight: .semibold))
                Text("创建一个，挂到日历上即可开始有计划地训练")
                    .font(.system(size: 12))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .multilineTextAlignment(.center)
                Button {
                    createNewTemplate()
                } label: {
                    Text("新建模板")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.bottom, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(templates.prefix(5)) { tpl in
                    Button {
                        pendingPlanTemplate = tpl
                    } label: {
                        TemplateRowItem(template: tpl, accent: accent)
                    }
                    .buttonStyle(.plain)
                    if tpl.id != templates.prefix(5).last?.id {
                        Divider().padding(.leading, 32)
                    }
                }
            }
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.bottom, 14)
        }
    }

    private var quickStartGrid: some View {
        let lastWorkout = workouts.first
        return HStack(spacing: 8) {
            QuickStartTile(
                icon: "arrow.uturn.backward",
                title: "重做上次",
                subtitle: lastWorkout.flatMap {
                    ExerciseLookup.exercise(byId: $0.exerciseId)?.nameZH
                } ?? "—"
            ) {
                if let last = lastWorkout, let tpl = templates.first(where: {
                    $0.items.contains(where: { $0.exerciseId == last.exerciseId })
                }) {
                    pendingPlanTemplate = tpl
                }
            }
            QuickStartTile(
                icon: "calendar",
                title: "上周同日",
                subtitle: lastWeekTemplateLabel
            ) {
                if let tpl = lastWeekTemplate { pendingPlanTemplate = tpl }
            }
            QuickStartTile(
                icon: "plus",
                title: "空白训练",
                subtitle: "边练边记"
            ) {
                createNewTemplate()
            }
        }
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.bottom, 16)
    }

    private var lastWeekTemplate: Template? {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) else { return nil }
        let dayStart = cal.startOfDay(for: weekAgo)
        return allPlans.first(where: { cal.isDate($0.date, inSameDayAs: dayStart) })
            .flatMap { p in templates.first(where: { $0.id == p.templateId }) }
    }

    private var lastWeekTemplateLabel: String {
        if let t = lastWeekTemplate { return t.name }
        return "无"
    }

    private func scheduledSource(plan: DayPlan) -> String? {
        if let last = workouts.first, plan.templateId != nil,
           Calendar.current.isDate(last.startedAt, equalTo: Date(), toGranularity: .weekOfYear) == false {
            return "重做 \(formatShort(last.startedAt))"
        }
        return nil
    }

    private func formatShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M·d"
        return f.string(from: date)
    }

    // MARK: - Status-driven banner

    private func bannerSectionTitle(for status: DayPlanStatus) -> String {
        switch status {
        case .scheduled:  return "已安排今日"
        case .inProgress: return "训练中"
        case .completed:  return "今日已完成"
        case .skipped:    return "今日跳过"
        case .missed:     return "昨日未完成"
        }
    }

    private func completedSummary(for plan: DayPlan) -> ScheduledTrainingCard.ScheduledSummary? {
        guard plan.status == .completed,
              let workoutId = plan.completedWorkoutId,
              let workout = workouts.first(where: { $0.id == workoutId })
        else { return nil }
        let dur = Int(workout.durationSeconds / 60)
        let vol = workout.totalVolumeKg
        let setCount = workout.sets.count
        let perSetVL = workout.sets.map(\.velocityLossPercent).filter { $0 > 0 }
        let avgVL = perSetVL.isEmpty ? 0 : perSetVL.reduce(0, +) / Double(perSetVL.count)
        return .init(durationMin: dur, totalVolumeKg: vol, setCount: setCount, avgVL: avgVL)
    }

    private func handlePrimary(plan: DayPlan, template: Template) {
        switch plan.status {
        case .scheduled:
            // Push to Watch + activate (V2) + give haptic. Fire-and-forget;
            // result-bearing variant is used by PlanView's spinner CTA.
            Task { _ = await TemplateSyncService.pushAndStart(template: template, on: plan.date) }
            Haptics.success()
        case .inProgress:
            // Best effort: nudge Watch by re-pushing the template + reactivating
            Task { _ = await TemplateSyncService.pushAndStart(template: template, on: plan.date) }
        case .completed:
            // 看复盘 → push WorkoutDetailView
            if let id = plan.completedWorkoutId {
                pendingWorkoutDetail = WorkoutDetailRoute(id: id)
            }
        case .skipped:
            // Re-schedule by opening PlanView
            pendingPlanTemplate = template
        case .missed:
            // Re-attempt or reschedule — fastest path is opening Plan
            pendingPlanTemplate = template
        }
    }

    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.2)) { pendingCelebration = nil }
    }

    @ViewBuilder
    private func weekStripCard(weekly: WeeklyAdherence) -> some View {
        let cal = Calendar.current
        let dayStatus: [Date: DayPlanStatus] = {
            var map: [Date: DayPlanStatus] = [:]
            for plan in allPlans where plan.date >= weekly.weekStart && plan.date < weekly.weekEnd {
                map[cal.startOfDay(for: plan.date)] = plan.status
            }
            return map
        }()
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("本周 \(weekly.completed)/\(weekly.planned)")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(weekStripCaption(weekly))
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            WeekProgressStrip(
                weekStart: weekly.weekStart,
                dayStatus: dayStatus,
                accent: accent
            )
        }
        .padding(12)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.bottom, 14)
    }

    private func weekStripCaption(_ w: WeeklyAdherence) -> String {
        if w.isFullyCompleted { return "满训" }
        if w.missed > 0 { return "已漏 \(w.missed)" }
        if w.skipped > 0 { return "跳过 \(w.skipped)" }
        if w.inProgress > 0 { return "训练中" }
        return "进行中"
    }

    private func handleSecondary(plan: DayPlan, template: Template) {
        switch plan.status {
        case .scheduled:
            // 编辑 → PlanView
            pendingPlanTemplate = template
        case .completed:
            // 再练一次 → push template + activate (creates new workout outside the plan)
            Task { _ = await TemplateSyncService.pushAndStart(template: template, on: Date()) }
            Haptics.success()
        case .inProgress, .skipped, .missed:
            break
        }
    }
}

// Hide swiftui keyboard on focus loss helper / haptics

enum Haptics {
    static func success() {
        #if canImport(UIKit)
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
        #endif
    }
    static func selection() {
        #if canImport(UIKit)
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
        #endif
    }
}

#if canImport(UIKit)
import UIKit
#endif
