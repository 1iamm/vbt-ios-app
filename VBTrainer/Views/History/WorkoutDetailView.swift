// WorkoutDetailView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 redesign: hero stats row + "查看综合时间轴" entry + per-exercise folding
// cards (every set's weight × reps × rest × mean-velocity, with PR badge and
// inline mini sparkline of velocity decay).

import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    let workoutId: UUID

    @Environment(\.modelContext) private var context
    @Query private var workouts: [Workout]
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query private var prs: [PersonalRecord]

    @State private var expanded: Set<Int> = [0] // expand the first exercise group

    init(workoutId: UUID) {
        self.workoutId = workoutId
        _workouts = Query(filter: #Predicate<Workout> { $0.id == workoutId })
        _prs = Query(filter: #Predicate<PersonalRecord> { $0.sourceWorkoutId == workoutId })
    }

    private var workout: Workout? {
        workouts.first
    }

    private var goal: TrainingGoal {
        profiles.first?.trainingGoal ?? .strength
    }

    private var accent: Color {
        GoalTheme.accent(for: goal)
    }

    @State private var editingFeedback = false
    @State private var draftRPE: Int = 7
    @State private var draftNotes: String = ""

    var body: some View {
        ScrollView {
            if let workout {
                VStack(alignment: .leading, spacing: 0) {
                    hero(workout: workout)
                    feedbackCard(workout: workout)
                    timelineEntry(workout: workout)
                    exerciseGroups(workout: workout)
                    Spacer().frame(height: 24)
                }
            } else {
                EmptyStateCard(title: "未找到训练记录", subtitle: "可能已被删除或未同步")
                    .padding(Tokens.Space.lg)
            }
        }
        .background(Tokens.Color.groupedBg.ignoresSafeArea())
        .navigationTitle(headerDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let workout {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ExerciseTrendView(exerciseId: workout.exerciseId)
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                    .tint(accent)
                }
            }
        }
        .sheet(isPresented: $editingFeedback) {
            if let workout {
                NavigationStack {
                    FeedbackEditorSheet(
                        rpe: $draftRPE, notes: $draftNotes,
                        accent: accent
                    ) {
                        workout.rpe = draftRPE
                        workout.notes = draftNotes.isEmpty ? nil : draftNotes
                        try? context.save()
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var headerDate: String {
        guard let workout else { return "训练详情" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "M 月 d 日"
        return f.string(from: workout.startedAt)
    }

    // MARK: - Hero

    private func hero(workout: Workout) -> some View {
        let allReps = workout.sets.flatMap(\.reps)
        let avgVel = allReps.isEmpty ? 0 : allReps.map(\.meanVelocity).reduce(0, +) / Double(allReps.count)
        let dur = Int(workout.durationSeconds / 60)
        let vol = workout.totalVolumeKg
        let setCount = workout.sets.count
        let exerciseName = ExerciseLookup.exercise(byId: workout.exerciseId)?.nameZH ?? workout.exerciseId
        let dayOfWeek: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "zh-Hans")
            f.dateFormat = "EEEE"
            return f.string(from: workout.startedAt)
        }()
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(dayOfWeek) · \(GoalTheme.label(for: goal))")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .textCase(.uppercase)
                HStack(alignment: .center, spacing: 8) {
                    Text(exerciseName)
                        .font(.system(size: 26, weight: .bold))
                        .tracking(-0.5)
                    if !prs.isEmpty {
                        Text("PR ×\(prs.count)")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(Tokens.Color.success)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Tokens.Color.success.opacity(0.16), in: Capsule())
                    }
                }
            }
            HStack(spacing: 18) {
                heroStat(value: "\(dur)", unit: "min", label: "时长")
                heroStat(
                    value: vol >= 1000 ? String(format: "%.1f", vol / 1000) : String(format: "%.0f", vol),
                    unit: vol >= 1000 ? "t" : "kg",
                    label: "训练量"
                )
                heroStat(value: "\(setCount)", unit: "组", label: "总组数")
                heroStat(value: String(format: "%.2f", avgVel), unit: "m/s", label: "均速")
            }
        }
        .padding(.horizontal, Tokens.Space.xl)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private func heroStat(value: String, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.3)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .textCase(.uppercase)
        }
    }

    // MARK: - Subjective feedback (RPE + notes)

    @ViewBuilder
    private func feedbackCard(workout: Workout) -> some View {
        let hasRPE = workout.rpe != nil
        let hasNotes = workout.notes?.isEmpty == false
        let hasFeedback = hasRPE || hasNotes
        Button {
            draftRPE = workout.rpe ?? 7
            draftNotes = workout.notes ?? ""
            editingFeedback = true
        } label: {
            HStack(spacing: 10) {
                if hasFeedback {
                    if let rpe = workout.rpe {
                        rpeBadge(rpe)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if let rpe = workout.rpe {
                            Text("RPE \(rpe) · \(rpeLabel(rpe))")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        if let notes = workout.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.system(size: 12))
                                .foregroundStyle(Tokens.Color.secondaryLabel)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(accent)
                    Text("补写感受 · RPE / 笔记")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accent)
                    Spacer()
                }
            }
            .padding(14)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.bottom, 12)
    }

    private func rpeBadge(_ rpe: Int) -> some View {
        ZStack {
            Circle().stroke(Tokens.Color.fill, lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(rpe) / 10.0)
                .stroke(rpeRingColor(rpe), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(rpe)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 38, height: 38)
    }

    private func rpeRingColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...4: Tokens.Color.success
        case 5...7: accent
        case 8...9: Tokens.Color.warning
        default: Tokens.Color.danger
        }
    }

    private func rpeLabel(_ rpe: Int) -> String {
        switch rpe {
        case 1...3: "轻松"
        case 4...5: "中等"
        case 6...7: "偏重"
        case 8...9: "很重"
        default: "极限"
        }
    }

    // MARK: - Timeline entry

    private func timelineEntry(workout: Workout) -> some View {
        NavigationLink {
            ComprehensiveTimelineLandscape(workout: workout)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.14))
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("查看综合时间轴")
                        .font(.system(size: 14, weight: .semibold))
                    Text("横屏 · HR + 速度 + 组带 + VL")
                        .font(.system(size: 11))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            .padding(14)
            .cardStyle()
            .padding(.horizontal, Tokens.Space.lg)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 14)
    }

    // MARK: - Per-exercise folding cards

    @ViewBuilder
    private func exerciseGroups(workout: Workout) -> some View {
        // V1 has one exercise per workout. Group sets together; future workouts
        // with multiple exercises (template-driven) will show separate cards.
        let groups: [(exId: String, sets: [WorkoutSet])] = // Treat all sets as belonging to the workout's exerciseId for now.
            [(workout.exerciseId, workout.sets.sorted { $0.index < $1.index })]
        VStack(spacing: 10) {
            ForEach(Array(groups.enumerated()), id: \.offset) { idx, group in
                exerciseCard(idx: idx, exId: group.exId, sets: group.sets)
            }
        }
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func exerciseCard(idx: Int, exId: String, sets: [WorkoutSet]) -> some View {
        let exName = ExerciseLookup.exercise(byId: exId)?.nameZH ?? exId
        let isOpen = expanded.contains(idx)
        let workSets = sets.filter { ($0.targetReps ?? 0) > 0 || $0.weightKg > 0 }
        let avgVel = sets.flatMap(\.reps).map(\.meanVelocity)
        let velocities = sets.map { s -> Double in
            let reps = s.reps.map(\.meanVelocity)
            return reps.isEmpty ? 0 : reps.reduce(0, +) / Double(reps.count)
        }.filter { $0 > 0 }
        let summaryReps = sets.first?.reps.count ?? 0
        let topWeight = Int(sets.map(\.weightKg).max() ?? 0)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    if isOpen { expanded.remove(idx) } else { expanded.insert(idx) }
                }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7).fill(Tokens.Color.fill)
                            .frame(width: 26, height: 26)
                        Text("\(idx + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .monospacedDigit()
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(exName)
                                .font(.system(size: 15, weight: .semibold))
                                .tracking(-0.2)
                            if !prs.isEmpty {
                                Text("PR")
                                    .font(.system(size: 8, weight: .semibold))
                                    .tracking(0.5)
                                    .foregroundStyle(Tokens.Color.success)
                                    .padding(.horizontal, 4).padding(.vertical, 1)
                                    .background(Tokens.Color.success.opacity(0.16), in: RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        Text("\(workSets.count)×\(summaryReps) @\(topWeight)kg")
                            .font(.system(size: 11, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                    }
                    Spacer(minLength: 0)
                    if velocities.count >= 2 {
                        MiniSparkline(values: velocities, color: Tokens.Color.Data.velocity)
                    }
                    Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            if isOpen {
                Divider()
                tableHeader
                ForEach(sets, id: \.id) { set in
                    Divider()
                    setRow(set)
                }
            }
        }
        .cardStyle()
    }

    private var tableHeader: some View {
        HStack(spacing: 6) {
            Text("组").frame(width: 28, alignment: .leading)
            Text("重量").frame(maxWidth: .infinity, alignment: .trailing)
            Text("次数").frame(maxWidth: .infinity, alignment: .trailing)
            Text("休息").frame(maxWidth: .infinity, alignment: .trailing)
            Text("均速").frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .medium))
        .tracking(0.6)
        .foregroundStyle(Tokens.Color.tertiaryLabel)
        .textCase(.uppercase)
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(Tokens.Color.fill.opacity(0.6))
    }

    private func setRow(_ set: WorkoutSet) -> some View {
        let avg = set.reps.isEmpty ? 0 : set.reps.map(\.meanVelocity).reduce(0, +) / Double(set.reps.count)
        let slow = avg > 0 && avg < 0.55
        let restStr: String = {
            let s = set.restAfterSeconds
            if s == 0 { return "—" }
            return String(format: "%d:%02d", s / 60, s % 60)
        }()
        return HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(accent.opacity(0.14))
                    .frame(width: 22, height: 22)
                Text("\(set.index)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
            }
            .frame(width: 28, alignment: .leading)
            cellText("\(Int(set.weightKg))", unit: "kg")
            cellText("\(set.reps.count)")
            cellText(restStr, mute: restStr == "—")
            HStack(spacing: 4) {
                if slow {
                    Circle().fill(Tokens.Color.Data.velocityLoss).frame(width: 4, height: 4)
                }
                Text(String(format: "%.2f", avg))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(slow ? Tokens.Color.Data.velocityLoss : Tokens.Color.label)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private func cellText(_ text: String, unit: String? = nil, mute: Bool = false) -> some View {
        HStack(spacing: 1) {
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(mute ? Tokens.Color.tertiaryLabel : Tokens.Color.label)
            if let unit {
                Text(unit).font(.system(size: 9))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Feedback editor sheet (RPE + notes)

struct FeedbackEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rpe: Int
    @Binding var notes: String
    let accent: Color
    let onSave: () -> Void

    private let presetTags = ["状态好", "状态一般", "技术问题", "腰累", "腿沉", "心率高"]

    var body: some View {
        Form {
            Section("RPE · 主观负荷 (1-10)") {
                VStack(spacing: 8) {
                    HStack {
                        Text("\(rpe)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(rpeColor)
                        Spacer()
                        Text(rpeLabel)
                            .font(.system(size: 13))
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                    }
                    Slider(value: Binding(
                        get: { Double(rpe) },
                        set: { rpe = Int($0.rounded()) }
                    ), in: 1...10, step: 1)
                        .tint(accent)
                }
                .padding(.vertical, 4)
            }

            Section("笔记") {
                TextField("今天的状态 / 技术问题 / 想做的调整", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(presetTags, id: \.self) { tag in
                            Button {
                                if !notes.contains(tag) {
                                    notes = notes.isEmpty ? tag : "\(notes) · \(tag)"
                                }
                            } label: {
                                Text(tag)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(accent)
                                    .padding(.horizontal, 9).padding(.vertical, 4)
                                    .background(accent.opacity(0.14), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("感受")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    onSave()
                    dismiss()
                }
                .bold()
                .foregroundStyle(accent)
            }
        }
    }

    private var rpeColor: Color {
        switch rpe {
        case 1...4: Tokens.Color.success
        case 5...7: accent
        case 8...9: Tokens.Color.warning
        default: Tokens.Color.danger
        }
    }

    private var rpeLabel: String {
        switch rpe {
        case 1: "极轻 · 暖身"
        case 2...3: "轻松"
        case 4...5: "中等"
        case 6...7: "偏重 · 挑战"
        case 8: "很重 · 接近极限"
        case 9: "极重 · 1-2 reps in reserve"
        default: "极限 · 不能再多一组"
        }
    }
}

/// Wrapper that locks the existing comprehensive chart into a forced-landscape
/// orientation while it's on screen. Keeps the chart implementation untouched.
struct ComprehensiveTimelineLandscape: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            ComprehensiveChartView(workout: workout)
                .frame(
                    width: max(geo.size.width, geo.size.height),
                    height: min(geo.size.width, geo.size.height)
                )
                .rotationEffect(
                    geo.size.width < geo.size.height ? .degrees(90) : .zero,
                    anchor: .topLeading
                )
                .offset(x: geo.size.width < geo.size.height ? geo.size.width : 0)
        }
        .navigationTitle("综合时间轴")
        .navigationBarTitleDisplayMode(.inline)
        .background(Tokens.Color.groupedBg.ignoresSafeArea())
    }
}
