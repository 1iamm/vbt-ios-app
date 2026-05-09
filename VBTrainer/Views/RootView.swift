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
    }
}

#Preview { RootView() }
