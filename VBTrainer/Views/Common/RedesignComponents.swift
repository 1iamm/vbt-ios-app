// RedesignComponents.swift
// VBTrainer · iPhone · 2026-05
//
// Reusable UI building blocks for the V4 5-step flow redesign:
//   - TodayHeader            big "今天" + 96 px Readiness ring + HRV/sleep/RHR strip
//   - ScheduledTrainingCard  highlight banner shown when today has a plan
//   - SectionHeader          uppercase tracked label + optional accent action
//   - TemplateRowItem        my-templates list row (left color bar + meta)
//   - AIRecommendationCard   purple AI card
//   - QuickStartTile         3-up "昨日重做 / 上周同日 / 空白" tile
//   - StartChipsBar          horizontal scroll start-point chips
//   - FoldableExerciseCard   collapsible per-set editor (Plan / Workout detail)
//   - MiniSparkline          tiny inline velocity curve
//   - IOSCalendarMonth       month grid in iOS native calendar visual language

import SwiftUI

// MARK: - 1. Today header

struct TodayHeader: View {
    let snapshot: ReadinessSnapshot?
    let goalAccent: Color

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "EEEE · M 月 d 日"
        return f
    }()

    private var ringColor: Color {
        guard let snap = snapshot else { return Tokens.Color.tertiaryLabel }
        switch snap.tier {
        case .green:        return Tokens.Color.success
        case .yellow:       return Tokens.Color.warning
        case .red:          return Tokens.Color.danger
        case .insufficient: return Tokens.Color.tertiaryLabel
        }
    }

    private var subtitle: String {
        guard let snap = snapshot else { return "数据建立中 · 先做几次训练" }
        switch snap.tier {
        case .green:        return "体能良好 · 适合中高强度"
        case .yellow:       return "保守训练 · 关注速度"
        case .red:          return "建议休息或低强度"
        case .insufficient: return "数据不足 · 建立 7 天基线"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.weekdayFormatter.string(from: Date()))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                        .tracking(0.5)
                    Text("今天")
                        .font(.system(size: 30, weight: .bold))
                        .tracking(-0.6)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                }
                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .stroke(Tokens.Color.fill, lineWidth: 7)
                    if let score = snapshot?.score {
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100.0)
                            .stroke(ringColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    VStack(spacing: 2) {
                        Text(snapshot?.score.map(String.init) ?? "—")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .tracking(-1)
                        Text("READY")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Tokens.Color.tertiaryLabel)
                            .tracking(1)
                    }
                }
                .frame(width: 96, height: 96)
                .padding(.trailing, 8)
            }

            HStack(spacing: 0) {
                miniMetric("HRV", value: snapshot?.hrv.map { String(Int($0)) } ?? "—",
                           delta: snapshot?.hrv != nil ? "实时" : nil, dividerLeading: false)
                miniMetric("睡眠",
                           value: snapshot?.sleepDurationHours.map { String(format: "%.1f", $0) } ?? "—",
                           delta: snapshot?.sleepDurationHours != nil ? "h" : nil)
                miniMetric("RHR",
                           value: snapshot?.restingHR.map(String.init) ?? "—",
                           delta: snapshot?.restingHR != nil ? "bpm" : nil)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Tokens.Color.fill, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, Tokens.Space.xl)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private func miniMetric(_ label: String, value: String, delta: String?,
                            dividerLeading: Bool = true) -> some View {
        HStack(spacing: 0) {
            if dividerLeading {
                Divider().frame(height: 26).padding(.horizontal, 12)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .tracking(0.6)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .tracking(-0.4)
                    if let delta {
                        Text(delta)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Tokens.Color.success)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 2. Section header (with optional accent action)

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var accent: Color = Tokens.Color.accent

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Tokens.Color.label)
            Spacer()
            if let action {
                Text(action)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accent)
            }
        }
        .padding(.horizontal, Tokens.Space.xl)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

// MARK: - 3. Scheduled training banner

struct ScheduledTrainingCard: View {
    let templateName: String
    let source: String?
    let onStartFromWatch: () -> Void
    let onEdit: () -> Void
    var accent: Color = Tokens.Color.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 4, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(templateName)
                        .font(.system(size: 16, weight: .bold))
                        .tracking(-0.3)
                    if let source {
                        Text("来自计划 · \(source)")
                            .font(.system(size: 11))
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                    }
                }
                Spacer(minLength: 0)
                Text("已安排")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(accent.opacity(0.16), in: Capsule())
            }
            HStack(spacing: 8) {
                Button(action: onStartFromWatch) {
                    HStack(spacing: 6) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 13, weight: .semibold))
                        Text("从 Watch 开始")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: accent.opacity(0.5), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                Button(action: onEdit) {
                    Text("编辑")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Tokens.Color.label)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, Tokens.Space.lg)
    }
}

// MARK: - 4. Template row (My Templates list)

struct TemplateRowItem: View {
    let template: Template
    var accent: Color = Tokens.Color.accent

    private var subtitle: String {
        let names = template.items
            .sorted { $0.index < $1.index }
            .compactMap { ExerciseLookup.exercise(byId: $0.exerciseId)?.nameZH }
        return names.prefix(3).joined(separator: " · ")
    }

    private var meta: String {
        let exCount = template.items.count
        let setCount = template.items.reduce(0) { $0 + $1.effectiveWorkSetCount }
        let est = max(20, setCount * 4)
        return "\(exCount) 动作 · \(setCount) 组 · ~\(est)min"
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.2)
                Text(subtitle.isEmpty ? "未配置动作" : subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .lineLimit(1)
                Text(meta)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }
}

// MARK: - 5. AI recommendation card (purple)

struct AIRecommendationCard: View {
    let rec: AIRecommendation

    private static let aiHue = Color(hex: "7C5CFF")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(rec.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(Self.aiHue)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Self.aiHue.opacity(0.16), in: RoundedRectangle(cornerRadius: 4))
                }
            }
            Text(rec.title)
                .font(.system(size: 15, weight: .bold))
                .tracking(-0.3)
            Text(rec.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Tokens.Color.secondaryLabel)
            Text(rec.reason)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Self.aiHue)
                .padding(.top, 2)
            Divider()
                .padding(.top, 6)
            Text(rec.meta)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .monospacedDigit()
        }
        .padding(14)
        .frame(width: 250, alignment: .leading)
        .background(Self.aiHue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Self.aiHue.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - 6. Quick start tile

struct QuickStartTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Tokens.Color.label)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Tokens.Color.label)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 7. Mini sparkline

struct MiniSparkline: View {
    let values: [Double]
    var color: Color = Tokens.Color.Data.velocity
    var width: CGFloat = 76
    var height: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let lo = values.min() ?? 0
            let hi = values.max() ?? (lo + 1)
            let span = max(0.001, hi - lo)
            Path { p in
                guard values.count > 1 else { return }
                for (i, v) in values.enumerated() {
                    let x = CGFloat(i) / CGFloat(values.count - 1) * w
                    let y = h - 2 - CGFloat((v - lo) / span) * (h - 4)
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: width, height: height)
    }
}

// MARK: - 8. iOS-native calendar month

struct IOSCalendarMonth: View {
    @Binding var month: Date  // any date within the month to display
    @Binding var selected: Date

    /// `markers[startOfDay]` describes which dots to draw for that day.
    let markers: [Date: [CalendarDot]]
    let onTap: (Date) -> Void

    enum CalendarDot: Equatable {
        case done(Color)
        case planned
        case cmj
    }

    private static let sysRed = Color(hex: "FF3B30")
    private static let sysBlue = Color(hex: "0A84FF")

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh-Hans")
        f.dateFormat = "yyyy 年 M 月"
        return f.string(from: month)
    }

    private func startOfMonth() -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        return cal.date(from: comps) ?? month
    }

    private func cells() -> [(Int?, Date?)] {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday-first per design
        let first = startOfMonth()
        let weekday = cal.component(.weekday, from: first)
        // weekday Sun=1..Sat=7. With firstWeekday=2 (Mon), offset = (weekday - 2 + 7) % 7
        let leading = (weekday - 2 + 7) % 7
        let daysIn = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        var out: [(Int?, Date?)] = []
        for _ in 0..<leading { out.append((nil, nil)) }
        for d in 1...daysIn {
            let date = cal.date(byAdding: .day, value: d - 1, to: first) ?? first
            out.append((d, date))
        }
        // pad to a multiple of 7 to keep grid stable
        while out.count % 7 != 0 { out.append((nil, nil)) }
        return out
    }

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let selectedDay = cal.startOfDay(for: selected)
        let weekdays = ["一","二","三","四","五","六","日"]
        let cells = cells()

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(monthLabel)
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(Self.sysRed)
                Spacer()
                HStack(spacing: 18) {
                    Button {
                        if let prev = cal.date(byAdding: .month, value: -1, to: month) {
                            month = prev
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Self.sysRed)
                    }
                    Circle().fill(Self.sysRed).frame(width: 6, height: 6)
                    Button {
                        if let next = cal.date(byAdding: .month, value: 1, to: month) {
                            month = next
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Self.sysRed)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 14)

            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(0.6)
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Tokens.Color.separator).frame(height: 0.5)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(0..<cells.count, id: \.self) { i in
                    let (dayNum, date) = cells[i]
                    if let dayNum, let date {
                        let isToday = cal.isDate(date, inSameDayAs: today)
                        let isSelected = cal.isDate(date, inSameDayAs: selectedDay)
                        let dots = markers[cal.startOfDay(for: date)] ?? []
                        Button { onTap(date) } label: {
                            VStack(spacing: 1) {
                                ZStack {
                                    if isToday {
                                        Circle().fill(Self.sysRed).frame(width: 28, height: 28)
                                    } else if isSelected {
                                        Circle()
                                            .fill(Tokens.Color.accent.opacity(0.16))
                                            .overlay(Circle().stroke(Tokens.Color.accent, lineWidth: 1.5))
                                            .frame(width: 28, height: 28)
                                    }
                                    Text("\(dayNum)")
                                        .font(.system(size: 16, weight: isToday ? .bold : (isSelected ? .semibold : .regular), design: .rounded))
                                        .monospacedDigit()
                                        .tracking(-0.3)
                                        .foregroundStyle(isToday ? .white : (isSelected ? Tokens.Color.accent : Tokens.Color.label))
                                        .frame(height: 28)
                                }
                                HStack(spacing: 3) {
                                    ForEach(dots.indices, id: \.self) { di in
                                        Circle().fill(color(for: dots[di])).frame(width: 5, height: 5)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                            .frame(height: 56)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 56)
                    }
                }
            }
        }
    }

    private func color(for dot: CalendarDot) -> Color {
        switch dot {
        case .done(let c): return c
        case .planned:     return Self.sysBlue
        case .cmj:         return Tokens.Color.Data.velocity
        }
    }
}

// MARK: - 9. Start chips bar (horizontal scroll)

struct StartChipsBar<T: Hashable>: View {
    struct Chip: Identifiable {
        let id: T
        let icon: String
        let label: String
    }
    let chips: [Chip]
    @Binding var selected: T
    var accent: Color = Tokens.Color.accent

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(chips) { c in
                    Button { selected = c.id } label: {
                        HStack(spacing: 5) {
                            Image(systemName: c.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(c.label)
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.2)
                        }
                        .foregroundStyle(selected == c.id ? accent : Tokens.Color.label)
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .background(
                            (selected == c.id ? accent.opacity(0.12) : Tokens.Color.fill),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Tokens.Space.lg)
        }
    }
}
