// IPhoneActiveWorkoutView.swift
// VBTrainer · iOS · 2026-05
//
// V1.x rewrite: multi-exercise + table-based set rows + inline edit +
// last-workout reference column. Mirrors Hevy / Strong / 训记 patterns.
//
// Layout:
//   ┌ topBar           — back · exercise name · 总时长 · 结束
//   ├ exercise carousel — 1/N progress + tap to switch
//   ├ restBanner       — only when phase == .resting
//   ├ exerciseCard     — table of sets (上次 / 重量 / 次数 / 状态)
//   ├ notesField       — collapsed; tap to expand
//   └ bottomCTA        — 完成本组 / 同上完成 / 跳过休息

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct IPhoneActiveWorkoutView: View {

    @StateObject var controller = IPhoneWorkoutController()
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showFinishConfirm = false
    @State private var editingTarget: EditTarget?
    @State private var elapsedTick: Date = Date()

    let initialItems: [TemplateItemSnapshot]
    let initialItemIndex: Int
    let templateId: UUID?

    init(item: TemplateItemSnapshot? = nil, templateId: UUID? = nil) {
        self.initialItems = item.map { [$0] } ?? []
        self.initialItemIndex = 0
        self.templateId = templateId
    }

    init(items: [TemplateItemSnapshot], startingIndex: Int = 0, templateId: UUID? = nil) {
        self.initialItems = items
        self.initialItemIndex = startingIndex
        self.templateId = templateId
    }

    private struct EditTarget: Identifiable {
        let id: UUID
        let kind: Kind
        enum Kind { case weight, reps }
    }

    private let elapsedTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            Tokens.Color.groupedBg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if controller.plannedItems.count > 1 {
                    exerciseStrip
                }
                if controller.phase == .resting {
                    restBanner
                }
                ScrollView {
                    VStack(spacing: 12) {
                        exerciseCard
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            bottomCTA
        }
        .navigationBarHidden(true)
        .onAppear {
            if controller.plannedItems.isEmpty {
                if !initialItems.isEmpty {
                    controller.preparePlan(items: initialItems, startingItemIndex: initialItemIndex, templateId: templateId)
                } else {
                    controller.prepareAdHoc(exerciseId: "back-squat")
                }
            }
        }
        .onReceive(elapsedTimer) { now in elapsedTick = now }
        .sheet(item: $editingTarget) { target in
            NumberPadSheet(
                title: target.kind == .weight ? "调整重量 (kg)" : "调整次数",
                initial: target.kind == .weight ? controller.currentWeightKg : Double(controller.currentReps),
                stepKg: target.kind == .weight ? 2.5 : 1,
                isInteger: target.kind == .reps
            ) { newValue in
                if target.kind == .weight {
                    controller.updateCurrentWeight(newValue)
                } else {
                    controller.updateCurrentReps(Int(newValue))
                }
            }
            .presentationDetents([.height(360)])
        }
        .confirmationDialog("结束训练？", isPresented: $showFinishConfirm) {
            Button("结束训练", role: .destructive) {
                controller.finishWorkout(context: context)
                dismiss()
            }
            Button("继续训练", role: .cancel) {}
        } message: {
            Text("已完成 \(controller.totalLoggedSets) 组 · 共 \(controller.plannedItems.count) 动作")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Tokens.Color.label)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(controller.exerciseDisplayName)
                    .font(.system(size: 16, weight: .heavy))
                Text(formatElapsed(elapsedTick.timeIntervalSince(controller.workoutStartedAt)))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .monospacedDigit()
            }
            Spacer()
            Button { showFinishConfirm = true } label: {
                Text("结束")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Tokens.Color.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Tokens.Color.danger.opacity(0.12), in: Capsule())
            }
            .padding(.trailing, 12)
        }
        .frame(height: 48)
        .background(.thinMaterial)
    }

    // MARK: - Exercise strip (multi-exercise nav)

    private var exerciseStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(controller.plannedItems.enumerated()), id: \.offset) { idx, item in
                        exerciseChip(idx: idx, item: item, proxy: proxy)
                            .id(idx)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .onAppear {
                proxy.scrollTo(controller.currentItemIndex, anchor: .center)
            }
            .onChange(of: controller.currentItemIndex) { _, newIdx in
                withAnimation { proxy.scrollTo(newIdx, anchor: .center) }
            }
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private func exerciseChip(idx: Int, item: TemplateItemSnapshot, proxy: ScrollViewProxy) -> some View {
        let isCurrent = idx == controller.currentItemIndex
        let done = controller.completedSetCount(forExerciseIndex: idx)
        let total = max(1, item.effectiveWorkSetCount)
        let allDone = done >= total
        let bg: Color = isCurrent
            ? Tokens.Color.accent
            : (allDone ? Tokens.Color.success.opacity(0.12) : Tokens.Color.card)
        let titleColor: Color = isCurrent
            ? .white
            : (allDone ? Tokens.Color.success : Tokens.Color.label)
        let subColor: Color = isCurrent ? .white.opacity(0.85) : Tokens.Color.secondaryLabel
        let strokeColor: Color = isCurrent ? .clear : Tokens.Color.secondaryLabel.opacity(0.15)

        Button {
            controller.switchToExercise(at: idx)
            withAnimation { proxy.scrollTo(idx, anchor: .center) }
        } label: {
            VStack(spacing: 2) {
                Text("\(idx + 1). \(exerciseName(item.exerciseId))")
                    .font(.system(size: 12, weight: isCurrent ? .heavy : .semibold))
                    .foregroundStyle(titleColor)
                Text("\(done)/\(total)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(subColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(bg, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rest banner

    private var restBanner: some View {
        let next = controller.currentPlannedSpecs.indices.contains(controller.currentSetIndex + 1)
            ? controller.currentPlannedSpecs[controller.currentSetIndex + 1]
            : nil
        return HStack(spacing: 10) {
            ZStack {
                Circle().stroke(Tokens.Color.accent.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: restProgress)
                    .stroke(Tokens.Color.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(formatTime(controller.restRemainingSec))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text("休息中")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(Tokens.Color.accent)
                if let n = next {
                    Text("下一组 \(formatKg(n.weightKg)) kg × \(n.reps)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Tokens.Color.label)
                        .monospacedDigit()
                }
            }
            Spacer()
            HStack(spacing: 6) {
                pillButton("−10s") { controller.adjustRestRemaining(by: -10) }
                pillButton("+10s") { controller.adjustRestRemaining(by: +10) }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Tokens.Color.accent.opacity(0.08))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Tokens.Color.accent.opacity(0.25)).frame(height: 0.5)
        }
    }

    private func pillButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Tokens.Color.label)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Tokens.Color.card, in: Capsule())
                .overlay(Capsule().stroke(Tokens.Color.secondaryLabel.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var restProgress: CGFloat {
        guard controller.restTotalSec > 0 else { return 0 }
        return CGFloat(controller.restTotalSec - controller.restRemainingSec) / CGFloat(controller.restTotalSec)
    }

    // MARK: - Exercise card (table)

    private var exerciseCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: "上次" comparison
            if let lastSummary = lastWorkout {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                    Text("上次 \(formatKg(lastSummary.topWeightKg))kg × \(lastSummary.topReps) · \(lastSummary.setCount) 组 · \(relativeDays(lastSummary.startedAt))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                        .monospacedDigit()
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            } else {
                HStack {
                    Text("首次训练此动作")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }

            // Column headers
            HStack(spacing: 0) {
                Text("#").frame(width: 28, alignment: .leading)
                Text("上次").frame(width: 70, alignment: .leading)
                Text("重量").frame(maxWidth: .infinity, alignment: .center)
                Text("次数").frame(width: 50, alignment: .center)
                Text("").frame(width: 32)   // 勾选列
                Text("").frame(width: 28)   // 删除列
            }
            .font(.system(size: 10, weight: .heavy))
            .tracking(0.5)
            .foregroundStyle(Tokens.Color.tertiaryLabel)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider().padding(.leading, 14)

            // Rows
            VStack(spacing: 0) {
                ForEach(setRowModels) { row in
                    setRowView(row)
                    if row.id != setRowModels.last?.id {
                        Divider().padding(.leading, 14)
                    }
                }
            }

            // Add ad-hoc set (always shown so user can extend the plan any time).
            // 「加一组」只追加一行空白未勾选条目，不触发休息；用户后续点行末
            // 圆圈或底部「完成本组」 才标记为完成。
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                controller.appendPendingSet()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("加一组")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Tokens.Color.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(Tokens.Color.card)
        }
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private struct SetRow: Identifiable {
        let id: UUID
        let displayIndex: Int
        let plannedWeight: Double
        let plannedReps: Int
        let actual: IPhoneWorkoutController.LoggedSet?
        let isCurrent: Bool
    }

    private var setRowModels: [SetRow] {
        // 现在控制器会在 preparePlan 时按 specs 预填 N 条 pending 条目，所以
        // 表格 1:1 对应 logged 数组，行 ↔ 条目恒等映射。
        let logged = controller.loggedSetsForCurrent
        var rows: [SetRow] = []
        // 「当前组」= 第一个未勾选条目；若全部勾选则没有「当前」行（currentIdx 越界）。
        let firstPending = logged.firstIndex(where: { !$0.completed })
        let currentIdx = firstPending ?? logged.count
        for i in 0..<logged.count {
            let actual = logged[i]
            let isCurrent = (i == currentIdx) && (controller.phase != .finished)
            rows.append(SetRow(
                id: actual.id,
                displayIndex: i + 1,
                plannedWeight: actual.weightKg,
                plannedReps: actual.reps,
                actual: actual,
                isCurrent: isCurrent
            ))
        }
        return rows
    }

    private func setRowView(_ row: SetRow) -> some View {
        // 现在每一行都对应一条 entry（preparePlan 时按 specs 预填）；
        // row.actual 永远非空，weight/reps 直接读 entry。
        let isDone = row.actual?.completed == true
        let isCurrent = row.isCurrent
        let displayWeight = row.actual?.weightKg ?? row.plannedWeight
        let displayReps = row.actual?.reps ?? row.plannedReps
        return HStack(spacing: 0) {
            // # column
            Text("\(row.displayIndex)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(isCurrent ? Tokens.Color.accent : Tokens.Color.secondaryLabel)
                .frame(width: 28, alignment: .leading)

            // 上次 column
            Text(lastSetReference(for: row.displayIndex))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .monospacedDigit()
                .frame(width: 70, alignment: .leading)

            // 重量 column
            cellView(
                value: formatKg(displayWeight),
                unit: "kg",
                isCurrent: isCurrent,
                isDone: isDone
            ) {
                guard isCurrent else { return }
                editingTarget = EditTarget(id: row.id, kind: .weight)
            }
            .frame(maxWidth: .infinity)

            // 次数 column
            cellView(
                value: "\(displayReps)",
                unit: nil,
                isCurrent: isCurrent,
                isDone: isDone
            ) {
                guard isCurrent else { return }
                editingTarget = EditTarget(id: row.id, kind: .reps)
            }
            .frame(width: 50)

            // 勾选 column — 点击翻转 completed 标志，保留数据。
            Button {
                toggleRow(row)
            } label: {
                statusBadge(isDone: isDone, isCurrent: isCurrent)
            }
            .buttonStyle(.plain)
            .frame(width: 32)

            // 删除 column — 真正从数组中删除整行（区别于「取消勾选」）。
            Button {
                deleteRow(row)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .stroke(Tokens.Color.secondaryLabel.opacity(0.18), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .frame(width: 28)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isCurrent ? Tokens.Color.accent.opacity(0.06) : Color.clear)
    }

    /// Map a SetRow to its index in `controller.loggedSetsForCurrent` so the
    /// controller can splice it out. Rows that are already 「done」 line up
    /// with the head of the logged array in order.
    private func loggedIndex(for row: SetRow) -> Int? {
        guard let actual = row.actual else { return nil }
        return controller.loggedSetsForCurrent.firstIndex(where: { $0.id == actual.id })
    }

    /// 点击行末勾选框：翻转该行的 completed 标志，**保留**该行 weight/reps 数据。
    /// 不弹确认对话框；用户可来回切多次。
    private func toggleRow(_ row: SetRow) {
        guard let loggedIdx = loggedIndex(for: row) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        controller.toggleSetCompleted(at: loggedIdx)
    }

    /// 点击行末 「×」 按钮：把整行从数组中移除（区别于 toggleRow 仅翻转勾选）。
    private func deleteRow(_ row: SetRow) {
        guard let loggedIdx = loggedIndex(for: row) else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.easeOut(duration: 0.18)) {
            controller.deleteLoggedSet(at: loggedIdx)
        }
    }

    private func cellView(value: String, unit: String?, isCurrent: Bool, isDone: Bool, onTap: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: isCurrent ? .heavy : .semibold, design: .rounded))
                .foregroundStyle(isDone ? Tokens.Color.label : (isCurrent ? Tokens.Color.label : Tokens.Color.secondaryLabel))
                .monospacedDigit()
            if let u = unit {
                Text(u)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isCurrent ? Tokens.Color.accent.opacity(0.10) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isCurrent ? Tokens.Color.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private func statusBadge(isDone: Bool, isCurrent: Bool) -> some View {
        Group {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Tokens.Color.success)
            } else if isCurrent {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 18))
                    .foregroundStyle(Tokens.Color.accent)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .frame(width: 36)
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                switch controller.phase {
                case .ready, .setActive:
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        controller.completeCurrentSet()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                            Text(completeButtonText)
                                .font(.system(size: 17, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Tokens.Color.accent, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Tokens.Color.accent.opacity(0.35), radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)

                case .setEnded:
                    Color.clear.frame(height: 52)

                case .resting:
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        controller.skipRest()
                    } label: {
                        Text("跳过休息 → 下一组")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Tokens.Color.label)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Tokens.Color.accent.opacity(0.5), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)

                case .finished:
                    Button {
                        controller.finishWorkout(context: context)
                        dismiss()
                    } label: {
                        Text("保存并结束")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Tokens.Color.success, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial)
        }
    }

    private var completeButtonText: String {
        let logged = controller.loggedSetsForCurrent
        let firstPending = logged.firstIndex(where: { !$0.completed })
        let nextIdx = firstPending ?? logged.count
        let pendingCount = logged.filter { !$0.completed }.count

        // 「完成最后一组」: 仅当当前 pending 是数组中最后一条 且 它是唯一剩下
        // 未勾选的条目时才显示；用户在中间几组未完成时不应误导成「最后一组」。
        if pendingCount == 1 && nextIdx == logged.count - 1 {
            return "完成最后一组"
        }
        // 「同上完成」: 当前 weight/reps 与最近一次已勾选条目完全一致。
        if let last = logged.last(where: { $0.completed }),
           last.weightKg == controller.currentWeightKg && last.reps == controller.currentReps {
            return "同上完成"
        }
        return "完成第 \(nextIdx + 1) 组"
    }

    // MARK: - Lookups

    private var lastWorkout: IPhoneWorkoutController.LastWorkoutSummary? {
        guard !controller.exerciseId.isEmpty else { return nil }
        return IPhoneWorkoutController.lastWorkoutSummary(
            exerciseId: controller.exerciseId,
            in: context
        )
    }

    private func lastSetReference(for displayIndex: Int) -> String {
        // V1: just show "—". V2 will load per-set history from last Workout.
        // Caller is fast since we display once per row regardless.
        return "—"
    }

    private func exerciseName(_ id: String) -> String {
        ExerciseLookup.exercise(byId: id)?.nameZH ?? id
    }

    // MARK: - Format helpers

    private func formatTime(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }

    private func formatElapsed(_ secs: TimeInterval) -> String {
        let s = max(0, Int(secs))
        let h = s / 3600
        let m = (s % 3600) / 60
        let r = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, r) }
        return String(format: "%d:%02d", m, r)
    }

    private func formatKg(_ v: Double) -> String {
        if v.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(v))" }
        return String(format: "%.1f", v)
    }

    private func relativeDays(_ d: Date) -> String {
        let days = Int(Date().timeIntervalSince(d) / 86400)
        if days == 0 { return "今天" }
        if days == 1 { return "昨天" }
        if days < 7 { return "\(days) 天前" }
        if days < 30 { return "\(days / 7) 周前" }
        return "\(days / 30) 月前"
    }
}

// MARK: - Numpad sheet

@available(iOS 17.0, *)
private struct NumberPadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let initial: Double
    let stepKg: Double
    let isInteger: Bool
    let onCommit: (Double) -> Void

    @State private var value: Double = 0
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Text(title).font(.system(size: 15, weight: .heavy))
                Spacer()
                Button("完成") {
                    onCommit(Double(text) ?? value)
                    dismiss()
                }
                .bold()
                .foregroundStyle(Tokens.Color.accent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(text.isEmpty ? "—" : text)
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Color.label)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)

            HStack(spacing: 14) {
                Button {
                    let v = max(0, value - stepKg)
                    value = v
                    text = isInteger ? "\(Int(v))" : formatKg(v)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Tokens.Color.label)
                        .frame(width: 44, height: 44)
                        .background(Tokens.Color.card, in: Circle())
                        .overlay(Circle().stroke(Tokens.Color.secondaryLabel.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)

                TextField("", text: $text)
                    .keyboardType(isInteger ? .numberPad : .decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(height: 44)
                    .padding(.horizontal, 12)
                    .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 10))

                Button {
                    let v = value + stepKg
                    value = v
                    text = isInteger ? "\(Int(v))" : formatKg(v)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Tokens.Color.label)
                        .frame(width: 44, height: 44)
                        .background(Tokens.Color.card, in: Circle())
                        .overlay(Circle().stroke(Tokens.Color.secondaryLabel.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 8)
        }
        .onAppear {
            value = initial
            text = isInteger ? "\(Int(initial))" : formatKg(initial)
        }
    }

    private func formatKg(_ v: Double) -> String {
        if v.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(v))" }
        return String(format: "%.1f", v)
    }
}
