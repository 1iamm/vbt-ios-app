// LVPChartView.swift
// VBTrainer · iPhone · 2026-05

import Charts
import SwiftUI

struct LVPChartView: View {
    let fit: LVPFit
    let points: [(load: Double, velocity: Double)]

    private var minLoad: Double {
        points.map(\.load).min() ?? 0
    }

    private var maxLoad: Double {
        points.map(\.load).max() ?? 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            HStack {
                Text("力速曲线 (LVP)")
                    .font(Tokens.Font.headline)
                Spacer()
                Text("R²=\(String(format: "%.2f", fit.r2))")
                    .font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }

            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                    PointMark(
                        x: .value("重量", p.load),
                        y: .value("速度", p.velocity)
                    )
                    .foregroundStyle(Tokens.Color.Data.velocity)
                }

                let xs: [Double] = stride(from: minLoad - 5, through: maxLoad + 5, by: 5).map { $0 }
                ForEach(xs, id: \.self) { x in
                    LineMark(
                        x: .value("重量", x),
                        y: .value("速度", fit.slope * x + fit.intercept),
                        series: .value("回归", "regression")
                    )
                    .foregroundStyle(Tokens.Color.accent)
                    .lineStyle(.init(lineWidth: 2))
                }
            }
            .frame(height: 200)

            HStack {
                Text("斜率 \(String(format: "%.4f", fit.slope))")
                Spacer()
                Text("截距 \(String(format: "%.2f", fit.intercept))")
                Spacer()
                Text("\(fit.pointCount) 个点")
            }
            .font(Tokens.Font.caption)
            .foregroundStyle(Tokens.Color.secondaryLabel)
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }
}
