// PRListView.swift
// VBTrainer · iPhone · 2026-05

import SwiftData
import SwiftUI

struct PRListView: View {
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) private var prs: [PersonalRecord]

    private var grouped: [(exerciseId: String, items: [PersonalRecord])] {
        let dict = Dictionary(grouping: prs) { $0.exerciseId }
        return dict.keys.sorted().map { key in
            (key, dict[key]!)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        Group {
            if prs.isEmpty {
                EmptyStateCard(
                    title: "暂无个人记录",
                    subtitle: "完成几次训练后，破纪录的成绩会自动出现在这里"
                )
                .padding(Tokens.Space.lg)
            } else {
                List {
                    ForEach(grouped, id: \.exerciseId) { group in
                        Section(ExerciseLookup.exercise(byId: group.exerciseId)?.nameZH ?? group.exerciseId) {
                            ForEach(group.items) { pr in
                                row(pr)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("个人记录")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ pr: PersonalRecord) -> some View {
        HStack {
            Image(systemName: prIcon(pr.kind))
                .foregroundStyle(Tokens.Color.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(prLabel(pr.kind))
                    .font(Tokens.Font.headline)
                Text(Self.dateFormatter.string(from: pr.achievedAt))
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            Spacer()
            Text(formattedValue(pr))
                .font(Tokens.Font.numericMedium)
                .foregroundStyle(Tokens.Color.label)
                .monospacedDigit()
        }
    }

    private func prIcon(_ kind: PRKind) -> String {
        switch kind {
        case .maxWeight: "scalemass.fill"
        case .e1RM: "speedometer"
        case .maxVolume: "chart.bar.fill"
        case .maxSingleRepVelocity: "bolt.fill"
        case .maxCMJ: "figure.run"
        }
    }

    private func prLabel(_ kind: PRKind) -> String {
        switch kind {
        case .maxWeight: "最大重量"
        case .e1RM: "e1RM 估算"
        case .maxVolume: "最大训练量"
        case .maxSingleRepVelocity: "最快单 Rep"
        case .maxCMJ: "最高 CMJ"
        }
    }

    private func formattedValue(_ pr: PersonalRecord) -> String {
        switch pr.kind {
        case .maxWeight, .e1RM:
            String(format: "%.1f kg", pr.value)
        case .maxVolume:
            String(format: "%.0f kg", pr.value)
        case .maxSingleRepVelocity:
            String(format: "%.2f m/s", pr.value)
        case .maxCMJ:
            String(format: "%.1f cm", pr.value)
        }
    }
}
