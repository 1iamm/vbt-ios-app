// TodayView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 redesign: header with big "今天" + 96pt Readiness ring; if a DayPlan
// exists for today, show a highlighted "已安排今日" banner with "从 Watch
// 开始" CTA; otherwise show AI recommendations + my templates + quick-start.
//
// Tapping a template / recommendation opens the single-screen Plan editor
// (PlanView). "从 Watch 开始" pushes the template snapshot to Watch.

import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var liveStore = LiveWorkoutStore.shared

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \ReadinessSnapshot.date, order: .reverse) private var readinessSnaps: [ReadinessSnapshot]
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @Query(sort: \DayPlan.date, order: .reverse) private var allPlans: [DayPlan]

    @State private var hasRefreshed = false
    @State private var pendingPlanTemplate: Template?
    @State private var pendingIPhonePlan: IPhonePlanRoute?
    @State private var pendingModeChoiceTemplate: Template?
    @State private var pendingModeChoicePlanDate: Date?
    @State private var pendingWorkoutDetail: WorkoutDetailRoute?
    @State private var showingTweaks = false
    @State private var cmjPromptShown = false
    @State private var pendingCelebration: CelebrationCard.Kind?
    /// De-dup celebration triggers: the same workout id can arrive via both
    /// `.vbtWorkoutImported` (Watch sync) and `DayPlanEventBus.completed`
    /// (scheduled-plan path) — we only want to celebrate once per workout.
    @State private var celebratedWorkoutIds: Set<UUID> = []

    struct WorkoutDetailRoute: Identifiable, Hashable {
        let id: UUID
    }

    struct IPhonePlanRoute: Identifiable, Equatable {
        let id = UUID()
        let items: [TemplateItemSnapshot]
        let templateId: UUID?
    }

    private var goal: TrainingGoal {
        profiles.first?.trainingGoal ?? .strength
    }

    private var accent: Color {
        GoalTheme.accent(for: goal)
    }

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
                    // 注：训练最小化时浮窗 by MainTabsView 全局 overlay 提供，
                    // 不再在 Today 顶部重复 banner。
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
                        .accessibilityIdentifier("today.scheduledCard")
                        .padding(.bottom, 12)
                    }

                    let recs = AIRecommendationEngine.recommendations(context: context)
                    if !recs.isEmpty {
                        SectionHeader(title: "AI 推荐", accent: Tokens.Color.ai)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(recs) { rec in
                                    Button {
                                        applyRecommendation(rec)
                                    } label: {
                                        AIRecommendationCard(rec: rec)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("today.aiRec.\(rec.kind.rawValue)")
                                }
                            }
                            .padding(.horizontal, Tokens.Space.lg)
                        }
                        .padding(.bottom, 8)
                    }

                    SectionHeader(title: "我的模板", action: "管理 →", accent: accent) {
                        NotificationCenter.default.post(name: .vbtSwitchToPlanTab, object: nil)
                    }
                    myTemplatesList

                    Spacer().frame(height: 24)
                }
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())
            .overlay(alignment: .topTrailing) {
                TweaksButton { showingTweaks = true }
                    .accessibilityIdentifier("today.tweaks")
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
                // Subscribe to DayPlan event bus (scheduled-plan completed path).
                for await event in DayPlanEventBus.shared.stream {
                    if case let .completed(_, workoutId) = event, let workoutId {
                        await MainActor.run { surfaceCelebration(for: workoutId) }
                    }
                }
            }
            // Watch-sync path (Task 2 USR-F12 P0). Ad-hoc unscheduled workouts
            // never publish a DayPlan .completed event because markCompleted
            // no-ops without a plan — so we also listen for the connectivity
            // notification, which fires on EVERY Watch→iPhone sync (after
            // PR detector has run). De-dup is handled by celebratedWorkoutIds.
            .onReceive(
                NotificationCenter.default.publisher(for: .vbtWorkoutImported)
            ) { note in
                if let id = note.object as? UUID {
                    surfaceCelebration(for: id)
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
            // V2.x 训练中实时观看 — 由 Watch 推送的 .ready/.repDetected/...
            // 驱动；isLive 翻 false 时自动 dismiss（.workoutEnded）。
            .fullScreenCover(isPresented: liveStoreBinding) {
                LiveWorkoutView()
            }
            // iPhone-only 训练（V2.x：无 Watch 用户）
            .fullScreenCover(item: $pendingIPhonePlan) { route in
                NavigationStack {
                    IPhoneActiveWorkoutView(items: route.items, startingIndex: 0, templateId: route.templateId)
                }
            }
            // 自动模式 + 有 Watch：让用户选择在哪练
            .confirmationDialog(
                "在哪里训练？",
                isPresented: modeChoiceBinding,
                titleVisibility: .visible,
                presenting: pendingModeChoiceTemplate
            ) { template in
                Button("在 Apple Watch 上练") {
                    let date = pendingModeChoicePlanDate ?? Date()
                    Task { _ = await TemplateSyncService.pushAndStart(template: template, on: date) }
                    pendingModeChoiceTemplate = nil
                    pendingModeChoicePlanDate = nil
                }
                Button("在 iPhone 上练") {
                    pendingIPhonePlan = planRoute(from: template)
                    pendingModeChoiceTemplate = nil
                    pendingModeChoicePlanDate = nil
                }
                Button("取消", role: .cancel) {
                    pendingModeChoiceTemplate = nil
                    pendingModeChoicePlanDate = nil
                }
            } message: { _ in
                Text("可在「我的 → 训练模式」中设为默认。")
            }
        }
    }

    private var modeChoiceBinding: Binding<Bool> {
        Binding(
            get: { pendingModeChoiceTemplate != nil },
            set: { newValue in
                if !newValue {
                    pendingModeChoiceTemplate = nil
                    pendingModeChoicePlanDate = nil
                }
            }
        )
    }

    /// Simple opacity pulse modifier for the banner's "live" dot.
    private struct PulseAnimation: ViewModifier {
        @State private var on = false
        func body(content: Content) -> some View {
            content
                .opacity(on ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: on)
                .onAppear { on = true }
        }
    }

    /// Compact banner shown at the top of Today while a training session is
    /// running but minimized. Tap to re-open the fullScreenCover.
    private func liveMinimizedBanner(payload: LiveProgressPayload) -> some View {
        Button {
            liveStore.expand()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .opacity(0.9)
                    .modifier(PulseAnimation())
                VStack(alignment: .leading, spacing: 2) {
                    Text("训练中 · \(payload.exerciseName)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Tokens.Color.label)
                    Text(bannerSubline(payload: payload))
                        .font(.system(size: 11))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                        .monospacedDigit()
                }
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func bannerSubline(payload: LiveProgressPayload) -> String {
        switch payload.phase {
        case .ready, .repDetected:
            let v = payload.lastRepVelocity.map { String(format: "%.2f m/s", $0) } ?? "—"
            return "第 \(payload.setIndex + 1) 组 · \(payload.currentRep)/\(payload.targetReps) · \(v)"
        case .setEnded:
            return "组结束 · \(payload.repVelocities.count) reps · VL \(Int(payload.vlPercent ?? 0))%"
        case .restCountdown:
            let s = payload.restRemainingSec ?? 0
            return "休息 \(s / 60):\(String(format: "%02d", s % 60)) · 下组 \(Int(payload.targetWeightKg))kg × \(payload.targetReps)"
        case .workoutEnded:
            return "训练完成"
        }
    }

    /// Snapshot all items of a Template for the iPhone-only controller
    /// (multi-exercise support).
    private func planRoute(from template: Template) -> IPhonePlanRoute? {
        let snap = TemplateSyncService.snapshot(of: template, on: Date())
        guard !snap.items.isEmpty else { return nil }
        return IPhonePlanRoute(items: snap.items, templateId: template.id)
    }

    /// Bridge LiveWorkoutStore.isLive @Published to fullScreenCover binding.
    /// Cover shows when session is live AND user hasn't minimized.
    private var liveStoreBinding: Binding<Bool> {
        Binding(
            get: { liveStore.isLive && !liveStore.isMinimized },
            set: { newValue in
                if !newValue {
                    // System-driven dismiss only happens on .workoutEnded
                    // (we set isLive=false). Manual minimize sets
                    // isMinimized=true and leaves isLive=true.
                    if !liveStore.isMinimized {
                        liveStore.clear()
                    }
                }
            }
        )
    }

    /// Route an AI recommendation to its correct destination.
    private func applyRecommendation(_ rec: AIRecommendation) {
        Haptics.selection()
        switch rec.kind {
        case .deload:
            guard let baseId = rec.templateIdHint,
                  let base = templates.first(where: { $0.id == baseId }) else
            {
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
                exerciseId: exId, lastTopWeight: weight, in: context
            )
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
                .accessibilityIdentifier("today.newTemplate")
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Tokens.Space.lg)
            .padding(.bottom, 12)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(templates.prefix(5).enumerated()), id: \.element.id) { idx, tpl in
                    Button {
                        pendingPlanTemplate = tpl
                    } label: {
                        TemplateRowItem(template: tpl, accent: accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("today.template.\(idx)")
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

    private func scheduledSource(plan _: DayPlan) -> String? {
        // templateId is non-Optional; check whether last week's workout
        // referenced the same template instead of nil-checking it.
        if let last = workouts.first,
           Calendar.current.isDate(last.startedAt, equalTo: Date(), toGranularity: .weekOfYear) == false
        {
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
        case .scheduled: "已安排今日"
        case .inProgress: "训练中"
        case .completed: "今日已完成"
        case .skipped: "今日跳过"
        case .missed: "昨日未完成"
        }
    }

    private func completedSummary(for plan: DayPlan) -> ScheduledTrainingCard.ScheduledSummary? {
        guard plan.status == .completed,
              let workoutId = plan.completedWorkoutId,
              let workout = workouts.first(where: { $0.id == workoutId }) else { return nil }
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
            // V2.x: route by mode preference:
            //  · forceIPhone / auto + no Watch → present iPhone training cover
            //  · forceWatch → push to Watch
            //  · auto + has Watch → confirmationDialog
            switch WorkoutModeResolver.preference {
            case .forceIPhone:
                pendingIPhonePlan = planRoute(from: template)
            case .forceWatch:
                Task { _ = await TemplateSyncService.pushAndStart(template: template, on: plan.date) }
            case .auto:
                if WorkoutModeResolver.hasWatch {
                    pendingModeChoiceTemplate = template
                    pendingModeChoicePlanDate = plan.date
                } else {
                    pendingIPhonePlan = planRoute(from: template)
                }
            }
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

    /// Single entry point used by both the DayPlanEventBus.completed path
    /// (scheduled workouts) and the .vbtWorkoutImported notification (Watch
    /// sync). De-dups by workoutId so a workout that hits both paths only
    /// celebrates once.
    private func surfaceCelebration(for workoutId: UUID) {
        guard !celebratedWorkoutIds.contains(workoutId) else { return }
        celebratedWorkoutIds.insert(workoutId)
        guard let kind = CelebrationResolver.resolve(
            completedWorkoutId: workoutId, context: context
        ) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            pendingCelebration = kind
        }
        Task {
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            await MainActor.run { dismissCelebration() }
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
