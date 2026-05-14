// HeartRateZonesDonut.swift
// VBTrainer · iPhone · 2026-05

import Charts
import SwiftData
import SwiftUI

struct HeartRateZonesDonut: View {
    let workout: Workout

    @Query private var profiles: [UserProfile]

    private var samples: [HeartRateSample] {
        guard let data = workout.heartRateSamplesData else { return [] }
        return (try? JSONDecoder().decode([HeartRateSample].self, from: data)) ?? []
    }

    private var hrMax: Int {
        profiles.first?.hrMax ?? 200
    }

    private var zoneSeconds: [HRZone: Int] {
        var bins: [HRZone: Int] = [:]
        for s in samples {
            let zone = HRZone.classify(bpm: s.bpm, hrMax: hrMax)
            bins[zone, default: 0] += 1 // each sample ≈ 1 second
        }
        return bins
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Text("心率区间分布")
                .font(Tokens.Font.headline)

            if samples.isEmpty {
                Text("无心率数据")
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            } else {
                Chart {
                    ForEach(HRZone.allCases) { zone in
                        let seconds = zoneSeconds[zone] ?? 0
                        if seconds > 0 {
                            SectorMark(
                                angle: .value("时长", seconds),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(zone.color)
                            .annotation(position: .overlay) {
                                Text("Z\(zone.index)")
                                    .font(Tokens.Font.caption)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .padding(.vertical, Tokens.Space.sm)

                HStack(spacing: Tokens.Space.lg) {
                    ForEach(HRZone.allCases) { zone in
                        VStack(spacing: 1) {
                            HStack(spacing: 4) {
                                Circle().fill(zone.color).frame(width: 8, height: 8)
                                Text("Z\(zone.index)")
                                    .font(Tokens.Font.caption)
                                    .foregroundStyle(Tokens.Color.label)
                            }
                            Text("\(zoneSeconds[zone] ?? 0)s")
                                .font(Tokens.Font.caption)
                                .foregroundStyle(Tokens.Color.secondaryLabel)
                        }
                    }
                }
            }
        }
        .padding(Tokens.Space.lg)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }
}

enum HRZone: String, CaseIterable, Identifiable {
    case z1, z2, z3, z4, z5

    var id: String {
        rawValue
    }

    var index: Int {
        switch self {
        case .z1: 1
        case .z2: 2
        case .z3: 3
        case .z4: 4
        case .z5: 5
        }
    }

    var color: Color {
        switch self {
        case .z1: Color.gray
        case .z2: Color.blue
        case .z3: Color.green
        case .z4: Color.orange
        case .z5: Color.red
        }
    }

    static func classify(bpm: Int, hrMax: Int) -> HRZone {
        let pct = Double(bpm) / Double(max(1, hrMax))
        switch pct {
        case 0..<0.6: return .z1
        case 0.6..<0.7: return .z2
        case 0.7..<0.8: return .z3
        case 0.8..<0.9: return .z4
        default: return .z5
        }
    }
}
