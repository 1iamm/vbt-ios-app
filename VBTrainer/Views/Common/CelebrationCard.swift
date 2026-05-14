// CelebrationCard.swift
// VBTrainer · iPhone · 2026-05
//
// Floats above the Today screen for ~6s after a DayPlan transitions to
// .completed. Reads adherence + PR data through the resolver enum to pick
// the most "high-emotion" reason: PR > weekly fully completed > streak
// milestone > generic done.
//
// Visual language:
//   - card with accent gradient background, white title + body
//   - dismiss with horizontal swipe or tap close
//   - subtle scale-in + spring animation
//   - haptic .success on appear

import SwiftData
import SwiftUI

struct CelebrationCard: View {
    let kind: Kind
    let onDismiss: () -> Void
    /// Optional "查看复盘 →" CTA. When non-nil, the card shows a small
    /// secondary button beside the dismiss X that opens the workout
    /// detail screen. Per Round 1 PM-F9 (P1): celebration without a
    /// path to "what actually happened" felt like a dead-end.
    var onViewDetail: (() -> Void)? = nil
    var accent: Color = Tokens.Color.accent

    enum Kind: Equatable {
        case prBeaten(exerciseName: String, valueLabel: String)
        case weeklyFullyCompleted(count: Int)
        case streakMilestone(days: Int)
        case generic
    }

    private var icon: String {
        switch kind {
        case .prBeaten: "trophy.fill"
        case .weeklyFullyCompleted: "checkmark.seal.fill"
        case .streakMilestone: "flame.fill"
        case .generic: "checkmark.circle.fill"
        }
    }

    private var title: String {
        switch kind {
        case let .prBeaten(name, _): "\(name) PR 破了"
        case let .weeklyFullyCompleted(n): "本周满训 · \(n)/\(n)"
        case let .streakMilestone(d): "连续 \(d) 天"
        case .generic: "今日完成"
        }
    }

    private var body_: String {
        switch kind {
        case let .prBeaten(_, v): "新纪录 \(v) — 已写入 PR 列表"
        case .weeklyFullyCompleted: "保持节奏，下周继续"
        case let .streakMilestone(d):
            switch d {
            case 3: "习惯成形中 — 连续 3 天"
            case 7: "稳定一周 — 真挺住了"
            case 14: "两周不间断 — 多数人到不了这"
            case 30: "一个月节奏 — 你已经赢了大多数"
            default: "连续 \(d) 天，持续累积"
            }
        case .generic: "训练数据已同步，去综合时间轴看复盘"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.white.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                Text(body_)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if let onViewDetail {
                Button(action: onViewDetail) {
                    Text("查看 →")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.22), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("celebration.viewDetail")
            }
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.18), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("celebration.dismiss")
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [accent, accent.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .shadow(color: accent.opacity(0.45), radius: 14, x: 0, y: 8)
        .padding(.horizontal, Tokens.Space.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { v in
                    if abs(v.translation.width) > 40 || v.translation.height < -20 {
                        onDismiss()
                    }
                }
        )
        .onAppear { Haptics.success() }
    }
}

/// Resolves which celebration to show after a completion event.
/// Internal because its result type (`CelebrationCard.Kind`) is internal.
@available(iOS 17.0, *)
enum CelebrationResolver {
    @MainActor
    static func resolve(
        completedWorkoutId: UUID?,
        context: ModelContext
    ) -> CelebrationCard.Kind? {
        // 1. PR check (highest priority)
        if let workoutId = completedWorkoutId {
            var fd = FetchDescriptor<PersonalRecord>(
                predicate: #Predicate { $0.sourceWorkoutId == workoutId },
                sortBy: [SortDescriptor(\.value, order: .reverse)]
            )
            fd.fetchLimit = 1
            if let pr = (try? context.fetch(fd))?.first {
                let exName = ExerciseLookup.exercise(byId: pr.exerciseId)?.nameZH ?? pr.exerciseId
                let valueLabel = switch pr.kind {
                case .maxWeight, .e1RM, .maxVolume: "\(Int(pr.value)) kg"
                case .maxSingleRepVelocity: String(format: "%.2f m/s", pr.value)
                case .maxCMJ: "\(Int(pr.value)) cm"
                }
                return .prBeaten(exerciseName: exName, valueLabel: valueLabel)
            }
        }
        // 2. Weekly fully completed
        let weekly = WeeklyAdherenceCalculator.compute(context: context)
        if weekly.isFullyCompleted {
            return .weeklyFullyCompleted(count: weekly.completed)
        }
        // 3. Streak milestone (3 / 7 / 14 / 30)
        let streak = WeeklyAdherenceCalculator.currentStreak(context: context)
        if [3, 7, 14, 30, 60, 100].contains(streak) {
            return .streakMilestone(days: streak)
        }
        // 4. Generic done — only when nothing more interesting fired
        return .generic
    }
}
