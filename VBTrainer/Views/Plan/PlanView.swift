// PlanView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 single-screen plan editor (训记 / Hevy 风格):
//   - Header: source line + 4-stat summary (动作 / 组 / 训练量 / 预估)
//   - Start chips strip
//   - Folding per-exercise cards: tap to expand → per-set table + add row buttons
//   - Sticky bottom CTA: Watch · 开始训练 · 日历同步
//
// Replaces the multi-page TemplateEditorView flow on the new Plan tab.

import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var template: Template
    var plannedDate: Date

    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]

    @State private var expandedItemId: UUID?
    @State private var editingSet: TemplateSetSpec?
    @State private var showingExercisePicker = false
    @State private var showingScheduleSheet = false
    @State private var pushState: PushState = .idle
    @State private var showingRename = false
    @State private var renameText: String = ""
    @State private var showingDeleteConfirm = false

    private enum PushState: Equatable {
        case idle
        case pushing                  // sendMessage in flight, show spinner
        case delivered                // Watch confirmed receipt
        case queued                   // fell back to transferUserInfo
        case failed(String)           // couldn't even queue
    }

    private var goal: TrainingGoal { profiles.first?.trainingGoal ?? .strength }
    private var accent: Color { GoalTheme.accent(for: goal) }

    private var orderedItems: [TemplateItem] {
        template.items.sorted { $0.index < $1.index }
    }

    private var summary: (ex: Int, sets: Int, volumeKg: Double, est: Int) {
        let ex = orderedItems.count
        let sets = orderedItems.reduce(0) { $0 + $1.effectiveWorkSetCount }
        let vol = orderedItems.reduce(0.0) { acc, item in
            if item.hasPerSetSpecs {
                let workSets = item.orderedSetSpecs.filter { $0.kind == .work }
                return acc + workSets.reduce(0.0) { $0 + $1.weightKg * Double($1.reps) }
            }
            let w = item.targetWeightKg ?? 0
            return acc + w * Double(item.targetSets) * Double(item.targetReps)
        }
        let est = max(20, sets * 4)
        return (ex, sets, vol, est)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSummary
                    startChips
                    exerciseList
                    addExerciseButton
                    Spacer().frame(height: 110)
                }
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())

            stickyCTA
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        renameText = template.name
                        showingRename = true
                    } label: { Label("重命名", systemImage: "pencil") }
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: { Label("删除模板", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(accent)
                }
            }
        }
        .alert("重命名模板", isPresented: $showingRename) {
            TextField("模板名称", text: $renameText)
                .textInputAutocapitalization(.never)
            Button("取消", role: .cancel) {}
            Button("保存") {
                let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                template.name = name
                template.updatedAt = Date()
                try? context.save()
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("名称不能为空。")
        }
        .alert("删除模板？", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                context.delete(template)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("将永久删除「\(template.name)」。该操作不可恢复。")
        }
        // iPhone-only 训练 cover 已移至 MainTabsView 全局承接，这里只触发启动。
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExercisePickerSheet { exercise in
                    addExerciseItem(exercise)
                    showingExercisePicker = false
                }
            }
        }
        .sheet(item: $editingSet) { set in
            NavigationStack {
                SetSpecEditorSheet(set: set, accent: accent)
            }
            .presentationDetents([.height(320), .medium])
        }
        .sheet(isPresented: $showingScheduleSheet) {
            NavigationStack {
                SchedulePlanSheet(template: template, accent: accent)
            }
            .presentationDetents([.height(360)])
        }
        .alert(pushAlertTitle, isPresented: pushAlertBinding) {
            Button("好的") { pushState = .idle }
        } message: {
            Text(pushAlertMessage)
        }
    }

    private var pushAlertBinding: Binding<Bool> {
        Binding(
            get: {
                switch pushState {
                case .delivered, .queued, .failed: return true
                case .idle, .pushing: return false
                }
            },
            set: { if !$0 { pushState = .idle } }
        )
    }

    private var pushAlertTitle: String {
        switch pushState {
        case .delivered: return "Watch 已激活"
        case .queued:    return "已加入队列"
        case .failed:    return "推送失败"
        default:         return ""
        }
    }

    private var pushAlertMessage: String {
        switch pushState {
        case .delivered: return "Watch 已自动跳到训练界面，可以开始了"
        case .queued:    return "Watch 暂时不可达。打开 Apple Watch 上的 VBTrainer 后会自动激活"
        case .failed(let msg): return "原因：\(msg)"
        default: return ""
        }
    }

    // MARK: - Header

    private var headerSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("来源")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                Text("自定义模板 · \(orderedItems.count) 动作")
                    .font(.system(size: 12))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                statBlock(value: "\(summary.ex)", label: "动作")
                statBlock(value: "\(summary.sets)", label: "组")
                statBlock(value: formatVolume(summary.volumeKg), label: "训练量",
                          unit: summary.volumeKg >= 1000 ? "t" : "kg")
                Spacer(minLength: 0)
                statBlock(value: "~\(summary.est)", label: "预估", unit: "min", alignment: .trailing)
            }
        }
        .padding(.horizontal, Tokens.Space.xl)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func statBlock(value: String, label: String, unit: String? = nil,
                           alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.5)
                if let unit {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
    }

    private func formatVolume(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1f", kg / 1000)
        }
        return String(format: "%.0f", kg)
    }

    // MARK: - Start chips

    private var startChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chipView(icon: "arrow.uturn.backward", label: "重做上次", active: true)
                chipView(icon: "calendar", label: "上周同日")
                chipView(icon: "doc.on.doc", label: "模板")
                chipView(icon: "star", label: "PR 重测")
                chipView(icon: "bolt.fill", label: "CMJ")
                chipView(icon: "plus", label: "空白")
            }
            .padding(.horizontal, Tokens.Space.lg)
        }
        .padding(.bottom, 14)
    }

    private func chipView(icon: String, label: String, active: Bool = false) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.2)
        }
        .foregroundStyle(active ? accent : Tokens.Color.label)
        .padding(.horizontal, 11).padding(.vertical, 7)
        .background(active ? accent.opacity(0.12) : Tokens.Color.fill, in: Capsule())
    }

    // MARK: - Exercise list

    private var exerciseList: some View {
        VStack(spacing: 8) {
            ForEach(orderedItems, id: \.id) { item in
                exerciseCard(item)
            }
        }
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func exerciseCard(_ item: TemplateItem) -> some View {
        let exName = ExerciseLookup.exercise(byId: item.exerciseId)?.nameZH ?? item.exerciseId
        let isOpen = expandedItemId == item.id
        return VStack(spacing: 0) {
            // Header row
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedItemId = isOpen ? nil : item.id
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Tokens.Color.fill)
                            .frame(width: 28, height: 28)
                        Text("\(item.index)")
                            .font(.system(size: 12, weight: .bold))
                            .monospacedDigit()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exName)
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(-0.2)
                            .foregroundStyle(Tokens.Color.label)
                        Text(secondaryLine(item))
                            .font(.system(size: 11))
                            .foregroundStyle(Tokens.Color.tertiaryLabel)
                    }
                    Spacer(minLength: 0)
                    if !isOpen {
                        Text(summaryLine(item))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Tokens.Color.label)
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
                setTableHeader
                setRows(for: item)
                Divider()
                addRowButtons(for: item)
                Divider()
                targetVelocityFooter(for: item)
            }
        }
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isOpen ? accent.opacity(0.3) : .clear, lineWidth: 1)
        )
    }

    private func secondaryLine(_ item: TemplateItem) -> String {
        let work = item.orderedSetSpecs.filter { $0.kind == .work }.count
        let warm = item.orderedSetSpecs.filter { $0.kind == .warmUp }.count
        if item.hasPerSetSpecs {
            return "\(work) 正式 · \(warm) 热身"
        }
        return "\(item.targetSets) 组 × \(item.targetReps) reps"
    }

    private func summaryLine(_ item: TemplateItem) -> String {
        let workSpecs = item.orderedSetSpecs.filter { $0.kind == .work }
        if !workSpecs.isEmpty {
            // 全空 sentinel（刚添加、无历史） → 提示用户填写。
            if workSpecs.allSatisfy({ $0.weightKg == 0 && $0.reps == 0 }) {
                return "未填写 · 点击下方组配置"
            }
            let uniqueWeights = Set(workSpecs.map(\.weightKg))
            let uniqueReps = Set(workSpecs.map(\.reps))
            // 所有正式组完全相同 → 紧凑显示「reps×组数 @重量」
            if uniqueWeights.count == 1 && uniqueReps.count == 1,
               let first = workSpecs.first {
                return "\(first.reps)×\(workSpecs.count) @\(Int(first.weightKg))kg"
            }
            // 各组不同 → 显示重量和次数范围，避免误导性的 5×3@60kg
            let wMin = Int(workSpecs.map(\.weightKg).min() ?? 0)
            let wMax = Int(workSpecs.map(\.weightKg).max() ?? 0)
            let rMin = workSpecs.map(\.reps).min() ?? 0
            let rMax = workSpecs.map(\.reps).max() ?? 0
            let weightStr = wMin == wMax ? "\(wMin)kg" : "\(wMin)-\(wMax)kg"
            let repStr = rMin == rMax ? "\(rMin) reps" : "\(rMin)-\(rMax) reps"
            return "\(weightStr) · \(repStr)"
        }
        let kg = item.targetWeightKg.map { "\(Int($0))kg" } ?? "—"
        return "\(item.targetReps)×\(item.targetSets) @\(kg)"
    }

    private var setTableHeader: some View {
        HStack(spacing: 8) {
            Text("组").frame(width: 32, alignment: .leading)
            Text("重量").frame(maxWidth: .infinity)
            Text("次数").frame(maxWidth: .infinity)
            Text("休息").frame(maxWidth: .infinity)
            Color.clear.frame(width: 16)
        }
        .font(.system(size: 9, weight: .medium))
        .tracking(0.6)
        .foregroundStyle(Tokens.Color.tertiaryLabel)
        .textCase(.uppercase)
        .padding(.horizontal, 14).padding(.vertical, 6)
    }

    @ViewBuilder
    private func setRows(for item: TemplateItem) -> some View {
        if item.orderedSetSpecs.isEmpty {
            // Backfill from legacy fields
            ForEach(0..<max(1, item.targetSets), id: \.self) { idx in
                Button {
                    let spec = TemplateSetSpec(
                        index: idx + 1,
                        kind: .work,
                        weightKg: item.targetWeightKg ?? 60,
                        reps: item.targetReps,
                        restSeconds: item.restSeconds
                    )
                    spec.item = item
                    item.setSpecs.append(spec)
                    context.insert(spec)
                    try? context.save()
                    editingSet = spec
                } label: {
                    setRow(tag: "\(idx + 1)",
                           weight: item.targetWeightKg ?? 60,
                           reps: item.targetReps,
                           rest: item.restSeconds,
                           kind: .work)
                }
                .buttonStyle(.plain)
            }
        } else {
            ForEach(item.orderedSetSpecs, id: \.id) { spec in
                Button {
                    editingSet = spec
                } label: {
                    setRow(tag: tagFor(spec),
                           weight: spec.weightKg,
                           reps: spec.reps,
                           rest: spec.restSeconds,
                           kind: spec.kind)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tagFor(_ spec: TemplateSetSpec) -> String {
        if spec.kind == .warmUp { return "W" }
        // Show 1-based work-set index
        let workSpecs = (spec.item?.orderedSetSpecs ?? []).filter { $0.kind == .work }
        if let idx = workSpecs.firstIndex(where: { $0.id == spec.id }) {
            return "\(idx + 1)"
        }
        return "\(spec.index)"
    }

    private func setRow(tag: String, weight: Double, reps: Int, rest: Int,
                        kind: TemplateSetKind) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(kind == .warmUp ? Tokens.Color.fill : accent.opacity(0.14))
                    .frame(width: 24, height: 24)
                Text(tag)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(kind == .warmUp ? Tokens.Color.tertiaryLabel : accent)
            }
            .frame(width: 32, alignment: .leading)

            cellPill(text: weight == 0 ? "—" : "\(Int(weight))", unit: "kg",
                     mute: weight == 0)
            cellPill(text: reps == 0 ? "—" : "\(reps)", unit: "次",
                     mute: reps == 0)
            cellPill(text: rest == 0 ? "—" : formatRest(rest), unit: nil,
                     mute: rest == 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .frame(width: 16)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func cellPill(text: String, unit: String?, mute: Bool = false) -> some View {
        HStack(spacing: 1) {
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(mute ? Tokens.Color.tertiaryLabel : Tokens.Color.label)
            if let unit {
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Tokens.Color.fill, in: RoundedRectangle(cornerRadius: 6))
    }

    private func formatRest(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func addRowButtons(for item: TemplateItem) -> some View {
        HStack(spacing: 6) {
            addRowButton(label: "+ 正式组", color: accent) {
                addSet(.work, to: item)
            }
            addRowButton(label: "+ 热身", color: Tokens.Color.secondaryLabel) {
                addSet(.warmUp, to: item)
            }
            Button {
                applyPyramid(to: item)
            } label: {
                Text("金字塔")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(Tokens.Color.fill, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private func addRowButton(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Tokens.Color.separator, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        }
        .buttonStyle(.plain)
    }

    private func targetVelocityFooter(for item: TemplateItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("目标速度")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.4)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .textCase(.uppercase)
                Text(velocityRangeLabel(item))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            Divider().frame(height: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text("VL 警戒")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.4)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .textCase(.uppercase)
                Text("\(Int(item.vlCeiling ?? GoalTheme.defaultVLCeiling(for: goal)))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Color.Data.velocityLoss)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Tokens.Color.fill.opacity(0.6))
    }

    private func velocityRangeLabel(_ item: TemplateItem) -> String {
        if let lo = item.targetVelocityMin, let hi = item.targetVelocityMax {
            return String(format: "%.2f–%.2f m/s", lo, hi)
        }
        return "—"
    }

    private var addExerciseButton: some View {
        Button {
            showingExercisePicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("添加动作")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(accent)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.top, 12)
    }

    private var stickyCTA: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    startOnIPhone()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "iphone")
                            .font(.system(size: 14, weight: .bold))
                        Text("在手机上练")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accent.opacity(0.55), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(pushState == .pushing)

                Button {
                    pushTemplateNow()
                } label: {
                    HStack(spacing: 6) {
                        if pushState == .pushing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                            Text("激活 Watch…")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "applewatch")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text("在表上练")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(accent, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: accent.opacity(0.5), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(pushState == .pushing)
            }
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                Text("加入日程")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Tokens.Color.secondaryLabel)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { showingScheduleSheet = true }
        }
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func startOnIPhone() {
        guard pushState != .pushing else { return }
        let snap = TemplateSyncService.snapshot(of: template, on: plannedDate)
        guard !snap.items.isEmpty else { return }
        IPhoneWorkoutController.shared.preparePlan(items: snap.items, templateId: template.id)
        Haptics.success()
    }

    private func squareButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Tokens.Color.label)
                .frame(width: 48, height: 48)
                .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func pushTemplateNow() {
        guard pushState != .pushing else { return }
        pushState = .pushing
        let templateRef = template
        let date = plannedDate
        Task { @MainActor in
            let result = await TemplateSyncService.pushAndStart(
                template: templateRef,
                on: date
            )
            switch result {
            case .delivered:
                Haptics.success()
                pushState = .delivered
            case .queued:
                Haptics.success()
                pushState = .queued
            case .failed(let msg):
                pushState = .failed(msg)
            }
        }
    }

    private func addSet(_ kind: TemplateSetKind, to item: TemplateItem) {
        let nextIndex = (item.setSpecs.map(\.index).max() ?? 0) + 1
        let lastWork = item.orderedSetSpecs.last(where: { $0.kind == .work })
        let weight: Double = {
            if kind == .warmUp { return (lastWork?.weightKg ?? item.targetWeightKg ?? 60) * 0.5 }
            return lastWork?.weightKg ?? item.targetWeightKg ?? 60
        }()
        let reps = lastWork?.reps ?? item.targetReps
        let rest = kind == .warmUp ? 60 : item.restSeconds
        let spec = TemplateSetSpec(index: nextIndex, kind: kind, weightKg: weight, reps: reps, restSeconds: rest)
        spec.item = item
        item.setSpecs.append(spec)
        context.insert(spec)
        try? context.save()
        Haptics.selection()
    }

    private func applyPyramid(to item: TemplateItem) {
        // 5-set pyramid: 50% / 70% / 85% / 95% / 100% of target weight
        let topWeight = item.orderedSetSpecs.last(where: { $0.kind == .work })?.weightKg
            ?? item.targetWeightKg ?? 100
        // Clear existing work sets, keep warm-ups
        let keepWarm = item.orderedSetSpecs.filter { $0.kind == .warmUp }
        for s in item.orderedSetSpecs where s.kind == .work {
            context.delete(s)
        }
        item.setSpecs = keepWarm
        let percentages = [0.5, 0.7, 0.85, 0.95, 1.0]
        let nextStart = (item.setSpecs.map(\.index).max() ?? 0) + 1
        for (i, pct) in percentages.enumerated() {
            let spec = TemplateSetSpec(
                index: nextStart + i,
                kind: .work,
                weightKg: round(topWeight * pct),
                reps: max(1, item.targetReps - i),
                restSeconds: item.restSeconds
            )
            spec.item = item
            item.setSpecs.append(spec)
            context.insert(spec)
        }
        try? context.save()
        Haptics.selection()
    }

    private func addExerciseItem(_ ex: Exercise) {
        let nextIndex = (template.items.map(\.index).max() ?? 0) + 1
        let history = lastWorkoutSpecs(for: ex.id)
        let item = TemplateItem(
            index: nextIndex,
            exerciseId: ex.id,
            // Mirror specs into legacy aggregate fields. 「未填写」 sentinel
            // when no history → 1 set / 0 reps / nil weight / 0 rest.
            targetSets: history.isEmpty ? 1 : history.count,
            targetReps: history.first?.reps ?? 0,
            targetWeightKg: history.first?.weight,
            targetVelocityRange: ex.defaultTargetVelocityRange,
            vlCeiling: ex.defaultVLCeiling,
            restSeconds: history.first?.restSeconds ?? 0,
            side: ex.isUnilateral ? .left : .both
        )
        item.template = template
        template.items.append(item)
        context.insert(item)

        // Always create explicit setSpecs so the table doesn't fall back to
        // the legacy 「3 默认行」 path.
        let specs: [(weight: Double, reps: Int, restSeconds: Int)] = history.isEmpty
            ? [(weight: 0, reps: 0, restSeconds: 0)]
            : history
        for (i, h) in specs.enumerated() {
            let spec = TemplateSetSpec(
                index: i + 1,
                kind: .work,
                weightKg: h.weight,
                reps: h.reps,
                restSeconds: h.restSeconds
            )
            spec.item = item
            item.setSpecs.append(spec)
            context.insert(spec)
        }
        try? context.save()
        expandedItemId = item.id
    }

    /// Look up the user's most recent Workout for `exerciseId` and return
    /// its sets as (weight, reps, rest) tuples — drives auto-prefill when
    /// the user adds a previously-trained exercise to a new template.
    private func lastWorkoutSpecs(for exerciseId: String) -> [(weight: Double, reps: Int, restSeconds: Int)] {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let last = try? context.fetch(descriptor).first else { return [] }
        return last.sets
            .sorted { $0.index < $1.index }
            .map { (weight: $0.weightKg, reps: $0.reps.count, restSeconds: $0.restAfterSeconds) }
    }
}

// MARK: - Per-set editor sheet

struct SetSpecEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var set: TemplateSetSpec
    let accent: Color

    var body: some View {
        Form {
            Section("类型") {
                Picker("类型", selection: Binding(
                    get: { set.kind },
                    set: { set.kind = $0 }
                )) {
                    Text("正式组").tag(TemplateSetKind.work)
                    Text("热身组").tag(TemplateSetKind.warmUp)
                }
                .pickerStyle(.segmented)
            }
            Section("参数") {
                Stepper(value: Binding(
                    get: { set.weightKg },
                    set: { set.weightKg = $0 }
                ), in: 0...500, step: 2.5) {
                    HStack {
                        Text("重量")
                        Spacer()
                        Text("\(set.weightKg, specifier: "%.1f") kg")
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                            .monospacedDigit()
                    }
                }
                Stepper(value: $set.reps, in: 1...30) {
                    HStack {
                        Text("次数")
                        Spacer()
                        Text("\(set.reps)")
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                            .monospacedDigit()
                    }
                }
                Picker("休息", selection: $set.restSeconds) {
                    ForEach([0, 30, 60, 75, 90, 105, 120, 150, 180, 210, 240], id: \.self) { sec in
                        Text(sec == 0 ? "不休息" : "\(sec / 60):\(String(format: "%02d", sec % 60))").tag(sec)
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    context.delete(set)
                    try? context.save()
                    dismiss()
                } label: {
                    Text("删除该组").frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("编辑组")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    try? context.save()
                    dismiss()
                }
                .bold()
                .foregroundStyle(accent)
            }
        }
    }
}

// MARK: - Schedule sheet

struct SchedulePlanSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let template: Template
    let accent: Color

    @State private var date: Date = Date()
    @State private var time: Date = {
        let cal = Calendar.current
        return cal.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    }()
    @State private var syncToCalendar = true
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section("日期") {
                DatePicker("训练日", selection: $date, displayedComponents: .date)
                DatePicker("时间", selection: $time, displayedComponents: .hourAndMinute)
            }
            Section {
                Toggle(isOn: $syncToCalendar) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color(hex: "0A84FF"))
                        Text("同步到 iPhone 日历")
                    }
                }
            } footer: {
                Text("将创建一个「\(EventKitService.calendarName)」日历事件，并提前 30 分钟提醒。")
            }
            if let msg = statusMessage {
                Section {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                }
            }
        }
        .navigationTitle("安排训练")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") { Task { await save() } }
                    .bold()
                    .foregroundStyle(accent)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
        }
    }

    private func save() async {
        let cal = Calendar.current
        let hh = cal.component(.hour, from: time)
        let mm = cal.component(.minute, from: time)
        let plan = DayPlanStore.schedule(
            templateId: template.id,
            on: date,
            timeMinutes: hh * 60 + mm,
            context: context
        )

        if syncToCalendar {
            #if os(iOS)
            // Use full access — write-only (iOS 17+) can't enumerate
            // calendars, which means upsert() can't pick a target calendar
            // and silently sends events to nowhere. Full access lets us
            // both create + read, and the resulting event shows in the iOS
            // Calendar app reliably.
            let granted: Bool
            if EventKitService.shared.isAuthorized {
                granted = true
            } else {
                granted = await EventKitService.shared.requestFullAccess()
            }
            if granted {
                do {
                    let id = try EventKitService.shared.upsert(
                        title: "训练 · \(template.name)",
                        date: plan.date,
                        timeMinutes: plan.scheduledTimeMinutes,
                        notes: "VBTrainer 自动生成 · 共 \(template.items.count) 个动作",
                        existingIdentifier: plan.eventKitIdentifier
                    )
                    plan.eventKitIdentifier = id
                    try? context.save()
                    statusMessage = "已同步到 iPhone 日历"
                } catch {
                    statusMessage = "日历写入失败：\(error.localizedDescription)"
                }
            } else {
                statusMessage = "未授权日历访问"
            }
            #endif
        }
        let templateRef = template
        let date = plan.date
        Task { _ = await TemplateSyncService.pushAndStart(template: templateRef, on: date) }
        Haptics.success()
        dismiss()
    }
}
