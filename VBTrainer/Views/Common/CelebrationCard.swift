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

import SwiftUI
import SwiftData

struct CelebrationCard: View {
    let kind: Kind
    let onDismiss: () -> Void
    var accent: Color = Tokens.Color.accent

    enum Kind: Equatable {
        case prBeaten(exerciseName: String, valueLabel: String)
        case weeklyFullyCompleted(count: Int)
        case streakMilestone(days: Int)
        case generic
    }

    private var icon: String {
        switch kind {
        case .prBeaten:               return "trophy.fill"
        case .weeklyFullyCompleted:   return "checkmark.seal.fill"
        case .streakMilestone:        return "flame.fill"
        case .generic:                return "checkmark.circle.fill"
        }
    }

    private var title: String {
        switch kind {
        case .prBeaten(let name, _):           return "\(name) PR 破了"
        case .weeklyFullyCompleted(let n):     return "本周满训 · \(n)/\(n)"
        case .streakMilestone(let d):          return "连续 \(d) 天"
        case .generic:                          return "今日完成"
        }
    }

    private var body_: String {
        switch kind {
        case .prBeaten(_, let v):               return "新纪录 \(v) — 已写入 PR 列表"
        case .weeklyFullyCompleted:             return "保持节奏，下周继续"
        case .streakMilestone(let d):
            switch d {
            case 3:  return "习惯成形中 — 连续 3 天"
            case 7:  return "稳定一周 — 真挺住了"
            case 14: return "两周不间断 — 多数人到不了这"
            case 30: return "一个月节奏 — 你已经赢了大多数"
            default: return "连续 \(d) 天，持续累积"
            }
        case .generic:                          return "训练数据已同步，去综合时间轴看复盘"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.white.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
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
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.18), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [accent, accent.opacity(0.78)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
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
@available(iOS 17.0, *)
public enum CelebrationResolver {

    @MainActor
    public static func resolve(
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
                let valueLabel: String = {
                    switch pr.kind {
                    case .maxWeight, .e1RM, .maxVolume: return "\(Int(pr.value)) kg"
                    case .maxSingleRepVelocity:         return String(format: "%.2f m/s", pr.value)
                    case .maxCMJ:                       return "\(Int(pr.value)) cm"
                    }
                }()
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
