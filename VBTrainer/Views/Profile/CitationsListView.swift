// CitationsListView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI

struct CitationsListView: View {
    private var groupedCitations: [(topic: CitationTopic, items: [PaperCitation])] {
        CitationTopic.allCases.compactMap { topic in
            let items = Citations.byTopic(topic)
            return items.isEmpty ? nil : (topic, items)
        }
    }

    var body: some View {
        List {
            Section {
                Text("VBTrainer V1 的所有算法（Rep 识别 / 速度计算 / VL% / V1RM / e1RM / Readiness / CMJ）都建立在以下学术文献之上。点击条目跳浏览器查看原文。")
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            ForEach(groupedCitations, id: \.topic) { group in
                Section(zhTopic(group.topic)) {
                    ForEach(group.items) { c in
                        if let url = URL(string: c.url) {
                            Link(destination: url) {
                                citationRow(c)
                            }
                        } else {
                            citationRow(c)
                        }
                    }
                }
            }
        }
        .navigationTitle("引用论文")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func citationRow(_ c: PaperCitation) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(c.shortForm)
                .font(Tokens.Font.headline)
                .foregroundStyle(Tokens.Color.label)
            Text(c.title)
                .font(Tokens.Font.footnote)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .lineLimit(3)
            Text(c.journal)
                .font(Tokens.Font.caption)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(.vertical, 4)
    }

    private func zhTopic(_ t: CitationTopic) -> String {
        switch t {
        case .appleWatchValidation: return "Apple Watch 测速验证"
        case .repDetection:         return "Rep 识别"
        case .velocityIntegration:  return "速度计算 / ZUPT"
        case .velocityLoss:         return "VL% 速度损失"
        case .v1RM:                 return "1RM 时参考速度"
        case .lvpAndE1RM:           return "力速曲线 / e1RM 估算"
        case .velocityVariant:      return "MV / MPV / PV 选择"
        case .heartRate:            return "心率 / HRmax"
        case .hrvReadiness:         return "HRV / 训练准备度"
        case .sleep:                return "睡眠"
        case .cmjNeuromuscular:     return "CMJ 神经肌肉评估"
        }
    }
}
