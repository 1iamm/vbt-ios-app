// RootView.swift
// VBTrainer · iPhone · 2026-05
//
// V4 5-step main flow:
//   ① 今天 (TodayView) — Readiness + scheduled card / templates / AI / quick start
//   ② 计划 (PlansListView → PlanView) — single-screen editor + weekly planner
//   ③ 历史 (HistoryView)  — iOS-native calendar + per-workout detail
//   ④ 统计 (StatsView)    — week-over-week headline + e1RM + Readiness trend
//   ⑤ 我的 (ProfileView)  — settings, exports, citations
//
// Watch is the "open it" tab in the design. iPhone never participates in the
// during-workout moment; it shows replay + complete history afterwards.

import SwiftUI
import SwiftData

struct RootView: View {

    @Query private var profiles: [UserProfile]

    var body: some View {
        if profiles.isEmpty {
            OnboardingView(onCompleted: { /* @Query auto-refreshes */ })
        } else {
            MainTabsView()
        }
    }
}

struct MainTabsView: View {

    enum Tab: Hashable { case today, plan, history, stats, profile }

    @State private var selection: Tab = .today
    @StateObject private var liveStore = LiveWorkoutStore.shared
    @ObservedObject private var iPhoneSession = IPhoneWorkoutController.shared

    /// fullScreenCover 是否展示：训练激活 && 用户没收起到悬浮窗。
    /// Setter 收到 false 时把训练标记为「最小化」 而不是结束。
    private var iPhoneSessionBinding: Binding<Bool> {
        Binding(
            get: { iPhoneSession.isActive && !iPhoneSession.isMinimized },
            set: { newValue in
                if !newValue && iPhoneSession.isActive {
                    iPhoneSession.minimize()
                }
            }
        )
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("今天", systemImage: "sun.max.fill") }
                .tag(Tab.today)

            PlansListView()
                .tabItem { Label("计划", systemImage: "doc.on.doc.fill") }
                .tag(Tab.plan)

            HistoryView()
                .tabItem { Label("历史", systemImage: "calendar") }
                .tag(Tab.history)

            StatsView()
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            ProfileView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(Tokens.Color.accent)
        .onReceive(NotificationCenter.default.publisher(for: .vbtSwitchToPlanTab)) { _ in
            selection = .plan
        }
        // 全局右下角悬浮窗 —— 训练中切到任何 tab 都能看到当前 phase 摘要，
        // 点击展开 cover。仅 isLive && isMinimized 时显示。
        .overlay(alignment: .bottomTrailing) {
            if liveStore.isLive && liveStore.isMinimized, let p = liveStore.payload {
                LiveWorkoutPiPBubble(payload: p, onTap: { liveStore.expand() })
                    .padding(.trailing, 14)
                    .padding(.bottom, 70)  // 在 TabBar 上方
                    .transition(.scale.combined(with: .opacity))
            }
            if iPhoneSession.isActive && iPhoneSession.isMinimized {
                IPhoneWorkoutPiPBubble(
                    controller: iPhoneSession,
                    onTap: { iPhoneSession.expand() }
                )
                .padding(.trailing, 14)
                .padding(.bottom, 70)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: liveStore.isMinimized)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: iPhoneSession.isMinimized)
        // iPhone-only 训练 cover（全局承接，避免分散在 TodayView / PlanView）
        .fullScreenCover(isPresented: iPhoneSessionBinding) {
            NavigationStack {
                IPhoneActiveWorkoutView()
            }
        }
    }
}

/// 全局浮动小窗 — 右下角，约 130×80pt 圆角矩形。
/// 训练相关 phase 显示「reps/总 reps + 心率」，休息显示「倒计时 + 下组重量」。
private struct LiveWorkoutPiPBubble: View {
    let payload: LiveProgressPayload
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                switch payload.phase {
                case .ready, .repDetected:
                    activeContent
                case .setEnded:
                    setEndedContent
                case .restCountdown:
                    restContent
                case .workoutEnded:
                    EmptyView()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.orange.opacity(0.6), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .frame(width: 145)
        }
        .buttonStyle(.plain)
    }

    private var activeContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                Text("训练中").font(.system(size: 9, weight: .heavy)).tracking(0.6)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(payload.currentRep)/\(payload.targetReps)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text("reps").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }
            if let hr = payload.heartRate, hr > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill").font(.system(size: 9)).foregroundStyle(.red)
                    Text("\(hr) bpm").font(.system(size: 11, weight: .semibold)).monospacedDigit()
                }
            }
        }
    }

    private var setEndedContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("本组完成").font(.system(size: 9, weight: .heavy)).tracking(0.6)
                .foregroundStyle(.secondary)
            Text("\(payload.repVelocities.count) reps · VL \(Int(payload.vlPercent ?? 0))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
    }

    private var restContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("休息").font(.system(size: 9, weight: .heavy)).tracking(0.6)
                .foregroundStyle(.secondary)
            Text(formatTime(payload.restRemainingSec ?? 0))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle((payload.restRemainingSec ?? 999) <= 10 ? Color.orange : Color.primary)
            Text("下组 \(Int(payload.targetWeightKg))kg × \(payload.targetReps)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func formatTime(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }
}

/// iPhone-only 训练的悬浮窗（区别于 LiveWorkoutPiPBubble，那个是 Watch 镜像用的）。
/// 同样定位在右下角，显示动作名 + 已完成/总组数 + 训练时长。
@available(iOS 17.0, *)
private struct IPhoneWorkoutPiPBubble: View {
    @ObservedObject var controller: IPhoneWorkoutController
    let onTap: () -> Void

    @State private var tick: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle().fill(Color.orange).frame(width: 6, height: 6)
                    Text("训练中").font(.system(size: 9, weight: .heavy)).tracking(0.6)
                        .foregroundStyle(.secondary)
                }
                Text(controller.exerciseDisplayName)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(controller.totalLoggedSets)/\(controller.totalPlannedSets) 组")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Text(formatElapsed(tick.timeIntervalSince(controller.workoutStartedAt)))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.orange.opacity(0.6), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .frame(width: 160)
        }
        .buttonStyle(.plain)
        .onReceive(timer) { tick = $0 }
    }

    private func formatElapsed(_ secs: TimeInterval) -> String {
        let s = max(0, Int(secs))
        let h = s / 3600, m = (s % 3600) / 60, r = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, r) }
        return String(format: "%d:%02d", m, r)
    }
}

#Preview { RootView() }
