// TweaksQuickSwitcher.swift
// VBTrainer · iPhone · 2026-05
//
// Right-corner-sheet that mirrors Claude Design's Tweaks panel: lets the user
// switch trainingGoal (爆发 / 力量 / 增肌 / 减脂 / 综合) in a single tap. The
// switch persists to UserProfile and the whole app's accent recolors via the
// @Query that drives GoalTheme everywhere.
//
// 数据密度 / Readiness 风格 are locked per project decisions (标准 / 圆环) so
// they're displayed read-only here for transparency.

import SwiftData
import SwiftUI

struct TweaksQuickSwitcher: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    private let goals: [(TrainingGoal, String, String)] = [
        (.power, "爆发", "速度第一 · 神经募集 · VL 警戒 10%"),
        (.strength, "力量", "重量优先 · 维持高速 · VL 警戒 20%"),
        (.muscle, "增肌", "代谢压力 · 较高 reps · VL 警戒 30%"),
        (.fatLoss, "减脂", "心率维持 · 短间歇 · VL 警戒 40%"),
        (.general, "综合", "平衡训练 · 速度+次数 · VL 警戒 25%")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("训练目标", subtitle: "切换后整个 App 主色与 VL 警戒线随之变化")
                    goalGrid
                    sectionHeader("数据密度", subtitle: "锁定为「标准」 — V2 后会再开放调整")
                    lockedRow(value: "标准", body: "保留聚合分数和必要细节，平衡之选")
                    sectionHeader("Readiness 风格", subtitle: "锁定为「圆环」 — Apple 原生美学")
                    lockedRow(value: "圆环", body: "Apple Fitness 风格的 ring 加分数")
                    Spacer().frame(height: 40)
                }
                .padding(.top, 4)
            }
            .background(Tokens.Color.groupedBg.ignoresSafeArea())
            .navigationTitle("Tweaks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .bold()
                        .foregroundStyle(GoalTheme.accent(for: profile.trainingGoal))
                }
            }
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .textCase(.uppercase)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Tokens.Color.secondaryLabel)
        }
        .padding(.horizontal, Tokens.Space.lg)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private var goalGrid: some View {
        VStack(spacing: 0) {
            ForEach(goals, id: \.0) { g, label, body in
                Button {
                    profile.trainingGoal = g
                    try? context.save()
                    Haptics.selection()
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(GoalTheme.accent(for: g))
                            .frame(width: 14, height: 14)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Tokens.Color.label)
                            Text(body)
                                .font(.system(size: 11))
                                .foregroundStyle(Tokens.Color.secondaryLabel)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        if profile.trainingGoal == g {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(GoalTheme.accent(for: g))
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                if g != goals.last?.0 {
                    Divider().padding(.leading, 38)
                }
            }
        }
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
    }

    private func lockedRow(value: String, body: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                Text(body)
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, Tokens.Space.lg)
    }
}

/// Small "tweaks" button used by TodayView header.
struct TweaksButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Tokens.Color.label)
                .frame(width: 36, height: 36)
                .background(Tokens.Color.fill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
