// RootView.swift
// VBTrainer · iPhone · 2026-05
//
// Top-level view. Shows OnboardingView until a UserProfile exists; then
// presents the 4-tab main UI.

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

    enum Tab: Hashable { case today, train, history, profile }

    @State private var selection: Tab = .today

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("今天", systemImage: "circle.lefthalf.filled") }
                .tag(Tab.today)

            TrainTabView()
                .tabItem { Label("训练", systemImage: "dumbbell.fill") }
                .tag(Tab.train)

            HistoryView()
                .tabItem { Label("历史", systemImage: "clock") }
                .tag(Tab.history)

            ProfileView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(Tokens.Color.accent)
    }
}

// 训练 Tab — 包含 Plans + Calendar 两个子视图
struct TrainTabView: View {
    @State private var section: TrainSection = .plans

    enum TrainSection: String, CaseIterable {
        case plans = "模板"
        case calendar = "日历"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("视图", selection: $section) {
                    ForEach(TrainSection.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Tokens.Space.lg)
                .padding(.vertical, Tokens.Space.sm)
                .background(Tokens.Color.groupedBg)

                switch section {
                case .plans:
                    PlansView()
                case .calendar:
                    ScrollView {
                        CalendarPlanView()
                            .padding(Tokens.Space.lg)
                    }
                    .background(Tokens.Color.groupedBg)
                }
            }
            .navigationTitle("训练计划")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview { RootView() }
