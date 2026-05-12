// IPhoneWorkoutController.swift
// VBTrainer · iOS · 2026-05
//
// Drives iPhone-only training (no Watch). V1.x: multi-exercise support
// — the controller now holds the entire plan, tracks a cursor across
// exercises, and saves one Workout row per exercise on finish (mirrors
// the Watch flow). Single-exercise legacy path is still supported.
//
// Phases mirror LiveProgressPayload semantics:
//   .ready → .setActive → .setEnded → .restCountdown → .ready (next set)
//     → ... → switch exercise → .ready → ... → .workoutEnded

import Foundation
import SwiftData
import SwiftUI

@available(iOS 17.0, *)
@MainActor
public final class IPhoneWorkoutController: ObservableObject {

    /// 全局单例：让训练状态在 fullScreenCover 被「最小化」 dismiss 后继续存活；
    /// view 关闭后用户从悬浮窗点回来还能看到原训练。
    public static let shared = IPhoneWorkoutController()

    public enum Phase: String { case ready, setActive, setEnded, resting, finished }

    @Published public private(set) var phase: Phase = .ready
    @Published public var currentWeightKg: Double = 0
    @Published public var currentReps: Int = 0
    @Published public private(set) var restRemainingSec: Int = 0
    @Published public private(set) var restTotalSec: Int = 0

    /// 训练是否在进行中（preparePlan → true；finishWorkout → false）。
    /// 驱动 RootView 的 fullScreenCover 是否展示。
    @Published public private(set) var isActive: Bool = false
    /// 用户点了 ▼ 收起到悬浮窗。isActive=true && isMinimized=true 时显示悬浮窗。
    @Published public var isMinimized: Bool = false

    /// Per-exercise logged sets, keyed by exercise index in plannedItems.
    /// 注意：本数组包含**所有**用户加入的组（含未勾选的「加一组」占位），
    /// 判定「已完成」时需用 `.filter { $0.completed }`。
    @Published public private(set) var loggedSetsByExercise: [Int: [LoggedSet]] = [:]
    @Published public private(set) var currentSetIndex: Int = 0
    @Published public private(set) var plannedItems: [TemplateItemSnapshot] = []
    @Published public private(set) var currentItemIndex: Int = 0
    @Published public var sessionNotes: String = ""

    public var currentItem: TemplateItemSnapshot? {
        plannedItems.indices.contains(currentItemIndex) ? plannedItems[currentItemIndex] : nil
    }
    public var currentPlannedSpecs: [TemplateSetSpecSnapshot] {
        (currentItem?.setSpecs ?? []).sorted { $0.index < $1.index }
    }
    public var loggedSetsForCurrent: [LoggedSet] {
        loggedSetsByExercise[currentItemIndex] ?? []
    }
    public var exerciseId: String { currentItem?.exerciseId ?? "" }
    public var exerciseDisplayName: String {
        guard let id = currentItem?.exerciseId else { return "" }
        return ExerciseLookup.exercise(byId: id)?.nameZH ?? id
    }
    /// Total sets across the whole session (work only — preserves what
    /// the bottom progress bar should show).
    public var totalPlannedSets: Int {
        plannedItems.reduce(0) { $0 + max(1, $1.effectiveWorkSetCount) }
    }
    public var totalLoggedSets: Int {
        loggedSetsByExercise.values.reduce(0) { $0 + $1.filter { $0.completed }.count }
    }
    /// 已勾选完成的组数（按动作索引），供 UI 显示 chip 进度等。
    public func completedSetCount(forExerciseIndex idx: Int) -> Int {
        (loggedSetsByExercise[idx] ?? []).filter { $0.completed }.count
    }
    public var workoutStartedAt: Date { startedAt }

    public struct LoggedSet: Identifiable, Equatable {
        public let id: UUID
        public let setIndex: Int
        public var weightKg: Double
        public var reps: Int
        public let rpe: Int?
        public let completedAt: Date
        /// false = 该行已存在但未勾选完成（用户「加一组」或主动取消勾选）。
        /// 仅 completed=true 的行才计入「已完成」、参与自动跳下一动作判定、
        /// 以及最终持久化进 SwiftData。
        public var completed: Bool
    }

    private var liveWorkoutId: UUID = UUID()
    private var startedAt: Date = Date()
    private var restTask: Task<Void, Never>?
    private var templateId: UUID?

    public init() {}

    // MARK: - Setup

    /// Multi-exercise entry. `startingItemIndex` lets the caller jump straight
    /// to a specific exercise (default 0). Replaces all session state.
    public func preparePlan(items: [TemplateItemSnapshot], startingItemIndex: Int = 0, templateId: UUID? = nil) {
        let sorted = items.sorted { $0.index < $1.index }
        plannedItems = sorted
        currentItemIndex = max(0, min(startingItemIndex, max(sorted.count - 1, 0)))
        self.templateId = templateId
        loggedSetsByExercise = [:]
        startedAt = Date()
        liveWorkoutId = UUID()
        loadCurrentItem()
        isActive = true
        isMinimized = false
    }

    /// 把训练收起到悬浮窗（不结束训练，状态保留）。
    public func minimize() { isMinimized = true }
    /// 从悬浮窗回到全屏 cover。
    public func expand() { isMinimized = false }

    /// 训练中追加一个新动作 tab 在末尾。默认 3 组 × 5 reps @ 60kg，90s 休息。
    /// 用户可以在新 tab 内编辑 cell / 加一组 / 删除组。追加后自动切到新 tab。
    public func appendExercise(_ exerciseId: String) {
        let nextIdx = plannedItems.count
        let snap = TemplateItemSnapshot(
            id: UUID(),
            index: nextIdx,
            exerciseId: exerciseId,
            targetSets: 3,
            targetReps: 5,
            targetWeightKg: 60,
            targetVelocityMin: nil,
            targetVelocityMax: nil,
            vlCeiling: nil,
            restSeconds: 90,
            sideRaw: "both",
            setSpecs: []
        )
        plannedItems.append(snap)
        currentItemIndex = nextIdx
        loadCurrentItem()  // 预填 3 条 pending entries
        if !isActive { isActive = true }
    }

    /// Single-exercise convenience (back-compat for ad-hoc / TodayView quick path).
    public func preparePlanned(item: TemplateItemSnapshot, templateId: UUID? = nil) {
        preparePlan(items: [item], templateId: templateId)
    }

    /// Ad-hoc empty workout — synthesizes a single TemplateItemSnapshot so
    /// the rest of the view code can stay uniform.
    public func prepareAdHoc(exerciseId: String, weightKg: Double = 60, reps: Int = 5) {
        let synthesizedItem = TemplateItemSnapshot(
            id: UUID(),
            index: 0,
            exerciseId: exerciseId,
            targetSets: 3,
            targetReps: reps,
            targetWeightKg: weightKg,
            targetVelocityMin: nil,
            targetVelocityMax: nil,
            vlCeiling: nil,
            restSeconds: 90,
            sideRaw: "both",
            setSpecs: []
        )
        preparePlan(items: [synthesizedItem])
    }

    private func loadCurrentItem() {
        currentSetIndex = 0
        let specs = currentPlannedSpecs
        let targetCount = max(specs.count, currentItem?.effectiveWorkSetCount ?? 0)

        // 关键：开训时按 specs / targetSets 预填 N 条 pending 条目，让每一行视图
        // = 一条条目。这样「加一组」 永远在末尾追加新行（而不是替换第一个 spec
        // 位），状态徽章点击也精确翻转用户点的那一行。
        let existing = loggedSetsByExercise[currentItemIndex] ?? []
        if existing.isEmpty && targetCount > 0 {
            var seed: [LoggedSet] = []
            for i in 0..<targetCount {
                let spec = i < specs.count ? specs[i] : nil
                seed.append(LoggedSet(
                    id: UUID(),
                    setIndex: i,
                    weightKg: spec?.weightKg ?? currentItem?.targetWeightKg ?? 60,
                    reps: spec?.reps ?? currentItem?.targetReps ?? 5,
                    rpe: nil,
                    completedAt: Date(),
                    completed: false
                ))
            }
            loggedSetsByExercise[currentItemIndex] = seed
        }

        let list = loggedSetsByExercise[currentItemIndex] ?? []
        if let pendingIdx = list.firstIndex(where: { !$0.completed }) {
            let pending = list[pendingIdx]
            currentWeightKg = pending.weightKg
            currentReps = pending.reps
            let spec = pendingIdx < specs.count ? specs[pendingIdx] : nil
            restTotalSec = spec?.restSeconds ?? currentItem?.restSeconds ?? 90
            restRemainingSec = restTotalSec
        } else if let item = currentItem {
            // 所有组已勾选完成（用户切回旧动作的场景）。
            currentWeightKg = item.targetWeightKg ?? 60
            currentReps = item.targetReps
            restTotalSec = item.restSeconds
            restRemainingSec = item.restSeconds
        }
        phase = .ready
        pushLive(.ready)
    }

    // MARK: - User actions

    public func completeCurrentSet(rpe: Int? = nil) {
        // 「完成本组」语义：把「当前正在进行的组」标记为完成 → 进入休息。
        // 当前组 = 第一个未勾选的条目；若所有条目都已勾选，则新建一条。
        if phase == .resting {
            restTask?.cancel()
            restTask = nil
        }
        guard phase == .ready || phase == .setActive || phase == .resting else { return }

        var list = loggedSetsByExercise[currentItemIndex] ?? []
        if let pendingIdx = list.firstIndex(where: { !$0.completed }) {
            // 已存在未勾选条目（用户先点了「加一组」或取消过勾选）→ 把这条标完成。
            // weight/reps 用条目自身已有值（用户可能改过）；不强制覆盖为 currentXxx。
            list[pendingIdx].completed = true
            list[pendingIdx] = LoggedSet(
                id: list[pendingIdx].id,
                setIndex: list[pendingIdx].setIndex,
                weightKg: list[pendingIdx].weightKg,
                reps: list[pendingIdx].reps,
                rpe: rpe ?? list[pendingIdx].rpe,
                completedAt: Date(),
                completed: true
            )
        } else {
            let logged = LoggedSet(
                id: UUID(),
                setIndex: currentSetIndex,
                weightKg: currentWeightKg,
                reps: currentReps,
                rpe: rpe,
                completedAt: Date(),
                completed: true
            )
            list.append(logged)
        }
        loggedSetsByExercise[currentItemIndex] = list
        phase = .setEnded
        pushLive(.setEnded)

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self?.beginRest()
        }
    }

    /// 「加一组」按钮：追加一条空白未勾选条目，不触发休息倒计时。
    /// 默认 weight/reps 取 currentWeightKg/Reps；用户后续可点击 cell 编辑。
    /// 若 phase 已是 .finished，会回退到 .ready 让用户继续训练。
    public func appendPendingSet() {
        var list = loggedSetsByExercise[currentItemIndex] ?? []
        let logged = LoggedSet(
            id: UUID(),
            setIndex: list.count,
            weightKg: currentWeightKg,
            reps: currentReps,
            rpe: nil,
            completedAt: Date(),
            completed: false
        )
        list.append(logged)
        loggedSetsByExercise[currentItemIndex] = list
        if phase == .finished { phase = .ready }
        pushLive(phase == .ready ? .ready : .setEnded)
    }

    /// 通过 cell 编辑修改「当前组」的 weight/reps。
    /// - 若当前组对应一个已存在的未勾选条目（用户先点了「加一组」），同步更新该条目。
    /// - 否则只更新 currentWeightKg/Reps 缓存（下一次 completeCurrentSet 会用到）。
    public func updateCurrentWeight(_ w: Double) {
        let clamped = max(0, min(500, w))
        currentWeightKg = clamped
        if var list = loggedSetsByExercise[currentItemIndex],
           let pendingIdx = list.firstIndex(where: { !$0.completed }) {
            list[pendingIdx].weightKg = clamped
            loggedSetsByExercise[currentItemIndex] = list
        }
    }
    public func updateCurrentReps(_ r: Int) {
        let clamped = max(1, min(99, r))
        currentReps = clamped
        if var list = loggedSetsByExercise[currentItemIndex],
           let pendingIdx = list.firstIndex(where: { !$0.completed }) {
            list[pendingIdx].reps = clamped
            loggedSetsByExercise[currentItemIndex] = list
        }
    }

    /// 直接 log 一组完成态条目（不触发休息），用于点击 planned 行末圆圈视为补勾选。
    public func addLoggedSet(weightKg: Double, reps: Int, atSetIndex slot: Int) {
        let logged = LoggedSet(
            id: UUID(),
            setIndex: slot,
            weightKg: weightKg,
            reps: reps,
            rpe: nil,
            completedAt: Date(),
            completed: true
        )
        var list = loggedSetsByExercise[currentItemIndex] ?? []
        list.append(logged)
        loggedSetsByExercise[currentItemIndex] = list
        pushLive(phase == .ready ? .ready : .setEnded)
    }

    /// 点击行末的勾选框：翻转 completed 标志，**保留**该行 weight/reps 数据。
    /// 若由 done → undone，取消正在进行的休息倒计时并把 phase 拉回 .ready，
    /// 这样用户可以重新做这一组。
    public func toggleSetCompleted(at index: Int) {
        guard var list = loggedSetsByExercise[currentItemIndex],
              list.indices.contains(index) else { return }
        let wasCompleted = list[index].completed
        list[index].completed.toggle()
        loggedSetsByExercise[currentItemIndex] = list

        if wasCompleted {
            // 取消勾选 → 中断 rest，回到 .ready 等用户重新完成。
            restTask?.cancel()
            restTask = nil
            phase = .ready
            pushLive(.ready)
        } else {
            pushLive(phase == .ready ? .ready : .setEnded)
        }
    }

    /// Delete a previously-logged set for the current exercise. Cancels any
    /// running rest countdown and snaps phase back to .ready so the user
    /// can re-do that slot. Index is the row position in
    /// `loggedSetsForCurrent` (0-based).
    public func deleteLoggedSet(at index: Int) {
        guard var list = loggedSetsByExercise[currentItemIndex],
              list.indices.contains(index) else { return }
        list.remove(at: index)
        loggedSetsByExercise[currentItemIndex] = list

        // 用户把当前动作的最后一条也删掉了 → 把该动作从 plan 中整体移除，
        // 切回上一个动作 tab（若该动作是第一个，则切到原来的第二个）。
        if list.isEmpty {
            removeCurrentExerciseAndGoBack()
            return
        }

        restTask?.cancel()
        restTask = nil
        let completedCount = list.filter { $0.completed }.count
        currentSetIndex = completedCount
        let specs = currentPlannedSpecs
        if currentSetIndex < specs.count {
            let next = specs[currentSetIndex]
            currentWeightKg = next.weightKg
            currentReps = next.reps
            restTotalSec = next.restSeconds
            restRemainingSec = next.restSeconds
        }
        phase = .ready
        pushLive(.ready)
    }

    /// 删除当前动作并切到「上一个」 tab。若整个 plan 删空则结束训练。
    private func removeCurrentExerciseAndGoBack() {
        restTask?.cancel()
        restTask = nil
        let removingIdx = currentItemIndex
        loggedSetsByExercise[removingIdx] = nil
        if plannedItems.indices.contains(removingIdx) {
            plannedItems.remove(at: removingIdx)
        }
        // loggedSetsByExercise 的 key 是按 plannedItems 的 index 编排的，
        // 移除 removingIdx 后，其后所有 key 需要 -1。
        var rekeyed: [Int: [LoggedSet]] = [:]
        for (k, v) in loggedSetsByExercise {
            if k > removingIdx { rekeyed[k - 1] = v }
            else if k < removingIdx { rekeyed[k] = v }
        }
        loggedSetsByExercise = rekeyed

        if plannedItems.isEmpty {
            // 整场训练被删空 → 结束。
            phase = .finished
            isActive = false
            isMinimized = false
            return
        }

        // 切到上一个 tab；若被删的是第 0 个，切到原来的第 1 个（现在的第 0 个）。
        currentItemIndex = removingIdx > 0 ? removingIdx - 1 : 0
        loadCurrentItem()
    }

    /// User jumped to a different exercise via the carousel/picker. Rest
    /// is interrupted; sets logged on the previous exercise remain.
    public func switchToExercise(at index: Int) {
        guard plannedItems.indices.contains(index), index != currentItemIndex else { return }
        restTask?.cancel()
        restTask = nil
        currentItemIndex = index
        loadCurrentItem()
    }

    public func skipRest() {
        restTask?.cancel()
        restTask = nil
        advanceToNextSet()
    }

    public func adjustRestRemaining(by delta: Int) {
        let newRemaining = max(5, min(600, restRemainingSec + delta))
        let newTotal = max(5, min(600, restTotalSec + delta))
        restRemainingSec = newRemaining
        restTotalSec = newTotal
        pushLive(.restCountdown)
    }

    private func beginRest() {
        phase = .resting
        restRemainingSec = restTotalSec
        startRestCountdown()
    }

    private func startRestCountdown() {
        restTask?.cancel()
        restTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while self.restRemainingSec > 0, !Task.isCancelled {
                self.pushLive(.restCountdown)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { self.restRemainingSec -= 1 }
            }
            if !Task.isCancelled {
                self.pushLive(.restCountdown)
                #if canImport(UIKit) && os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                self.advanceToNextSet()
            }
        }
    }

    private func advanceToNextSet() {
        currentSetIndex += 1
        let specs = currentPlannedSpecs
        let list = loggedSetsForCurrent
        // 总组数 = list 当前长度（用户加的「加一组」 已经把行算进 list）；
        // 若 list 为空（纯 legacy / ad-hoc），回退到 effectiveWorkSetCount。
        let totalForExercise = list.isEmpty
            ? (currentItem?.effectiveWorkSetCount ?? 0)
            : list.count
        let doneCount = list.filter { $0.completed }.count

        // 还有未勾选条目 → 留在当前动作，加载下一条 pending 的 weight/reps。
        if doneCount < totalForExercise {
            if let nextPendingIdx = list.firstIndex(where: { !$0.completed }) {
                let next = list[nextPendingIdx]
                currentWeightKg = next.weightKg
                currentReps = next.reps
                let spec = nextPendingIdx < specs.count ? specs[nextPendingIdx] : nil
                restTotalSec = spec?.restSeconds ?? currentItem?.restSeconds ?? restTotalSec
                restRemainingSec = restTotalSec
            }
            phase = .ready
            pushLive(.ready)
            return
        }

        // 当前动作所有组已完成 → 自动切到下一动作。
        if currentItemIndex + 1 < plannedItems.count {
            currentItemIndex += 1
            loadCurrentItem()
            return
        }

        // 纯 ad-hoc 单动作：无限继续。
        if plannedItems.count == 1 && totalForExercise == 0 {
            phase = .ready
            pushLive(.ready)
            return
        }

        // 全部动作完成 → 整场训练结束。
        phase = .finished
        pushLive(.workoutEnded)
    }

    public func finishWorkout(context: ModelContext? = nil, rpe: Int? = nil, notes: String? = nil) {
        restTask?.cancel()
        restTask = nil
        phase = .finished
        let endedAt = Date()
        let finalNotes = notes ?? (sessionNotes.isEmpty ? nil : sessionNotes)
        if let context {
            saveToSwiftData(context: context, endedAt: endedAt, rpe: rpe, notes: finalNotes)
        }
        pushLive(.workoutEnded)
        isActive = false
        isMinimized = false
    }

    // MARK: - Last-workout lookup

    /// Fetch the most recent completed Workout for a given exerciseId so the
    /// training table can show a "上次" comparison column. Returns nil if
    /// the user has never done this exercise.
    public static func lastWorkoutSummary(exerciseId: String, in context: ModelContext, excluding workoutId: UUID? = nil) -> LastWorkoutSummary? {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 5
        guard let results = try? context.fetch(descriptor) else { return nil }
        let candidate = results.first { $0.id != workoutId }
        guard let w = candidate else { return nil }
        let sets = w.sets.sorted { $0.index < $1.index }
        let topSet = sets.max { $0.weightKg < $1.weightKg }
        return LastWorkoutSummary(
            startedAt: w.startedAt,
            setCount: sets.count,
            topWeightKg: topSet?.weightKg ?? 0,
            topReps: topSet?.reps.count ?? 0
        )
    }

    public struct LastWorkoutSummary: Equatable {
        public let startedAt: Date
        public let setCount: Int
        public let topWeightKg: Double
        public let topReps: Int
    }

    // MARK: - Persistence

    private func saveToSwiftData(context: ModelContext, endedAt: Date, rpe: Int?, notes: String?) {
        // One Workout per exercise that actually got any logged sets.
        for (idx, item) in plannedItems.enumerated() {
            // 只持久化勾选完成的组；用户加了但未勾选的占位行不写入历史。
            let sets = (loggedSetsByExercise[idx] ?? []).filter { $0.completed }
            guard !sets.isEmpty else { continue }
            let workout = Workout(
                id: UUID(),
                startedAt: startedAt,
                endedAt: endedAt,
                exerciseId: item.exerciseId,
                notes: notes,
                rpe: rpe,
                linkedTemplateId: templateId,
                readinessSnapshotId: nil,
                source: .iPhone
            )
            context.insert(workout)
            for (setIdx, ls) in sets.enumerated() {
                let set = WorkoutSet(
                    index: setIdx,
                    weightKg: ls.weightKg,
                    restAfterSeconds: restTotalSec
                )
                set.workout = workout
                context.insert(set)
                for r in 0..<ls.reps {
                    let rep = Rep(
                        index: r + 1,
                        meanVelocity: 0,
                        peakVelocity: 0,
                        meanPropulsiveVelocity: nil,
                        timestamp: ls.completedAt,
                        metStatus: .met
                    )
                    rep.set = set
                    context.insert(rep)
                }
            }
            do {
                try context.save()
                NotificationCenter.default.post(name: .vbtWorkoutImported, object: workout.id)
            } catch {
                #if DEBUG
                print("[IPhoneWorkoutController] save error: \(error)")
                #endif
            }
        }
    }

    // MARK: - Live progress push
    //
    // 历史遗留：早期把 iPhone-only 训练的状态也镜像到 LiveWorkoutStore，结果
    // 触发了给「Watch 镜像」 用的 LiveWorkoutView 弹 fullScreenCover 盖在
    // IPhoneActiveWorkoutView 之上，按钮发往不存在的 Watch → 看起来「点了
    // 没反应」。LiveWorkoutStore 只该由 iPhoneConnectivityService 在收到
    // Watch 推送时写入，iPhone-only 流程读取 controller 自身状态即可。
    private func pushLive(_ p: LiveProgressPayload.Phase) {
        _ = p   // no-op: 保留方法签名，避免散布在 controller 各处的调用站都得改
    }
}
