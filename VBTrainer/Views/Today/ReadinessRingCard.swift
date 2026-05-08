// ReadinessRingCard.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct ReadinessRingCard: View {
    let snapshot: ReadinessSnapshot?

    private var score: Int? { snapshot?.score }
    private var tier: ReadinessTier { snapshot?.tier ?? .insufficient }

    private var ringColor: Color {
        switch tier {
        case .green:        return Tokens.Color.success
        case .yellow:       return Tokens.Color.warning
        case .red:          return Tokens.Color.danger
        case .insufficient: return Tokens.Color.tertiaryLabel
        }
    }

    private var tierLabel: String {
        switch tier {
        case .green:        return "状态良好 · 可正常训练"
        case .yellow:       return "保守训练"
        case .red:          return "建议休息或低强度"
        case .insufficient: return "数据不足，建议建立 7 天基线"
        }
    }

    var body: some View {
        VStack(spacing: Tokens.Space.md) {
            ZStack {
                Circle()
                    .stroke(Tokens.Color.fill, lineWidth: 12)
                if let score {
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 2) {
                    Text(score.map(String.init) ?? "—")
                        .font(Tokens.Font.numericLarge)
                        .foregroundStyle(Tokens.Color.label)
                        .monospacedDigit()
                    Text("Readiness")
                        .font(Tokens.Font.caption)
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }
            .frame(width: 180, height: 180)

            Text(tierLabel)
                .font(Tokens.Font.callout)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .multilineTextAlignment(.center)

            HStack(spacing: Tokens.Space.lg) {
                miniMetric(
                    "HRV",
                    value: snapshot?.hrv.map { "\(Int($0))" } ?? "—",
                    unit: "ms",
                    color: Tokens.Color.Data.heartRate
                )
                Divider().frame(height: 30)
                miniMetric(
                    "RHR",
                    value: snapshot?.restingHR.map { String($0) } ?? "—",
                    unit: "bpm",
                    color: Tokens.Color.Data.heartRate
                )
                Divider().frame(height: 30)
                miniMetric(
                    "睡眠",
                    value: snapshot?.sleepDurationHours.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "h",
                    color: Tokens.Color.Data.sleep
                )
            }
        }
        .padding(Tokens.Space.xl)
        .frame(maxWidth: .infinity)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }

    private func miniMetric(_ label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(unit)
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Text(label)
                .font(Tokens.Font.caption)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .textCase(.uppercase)
                .tracking(0.3)
        }
    }
}
