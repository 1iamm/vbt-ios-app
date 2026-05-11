// IPhoneActiveWorkoutView.swift
// VBTrainer · iOS · 2026-05
//
// iPhone-only training screen (no Watch). Per 3-round PM consensus + the
// senior trainer's hardest requirement: prefill last set's weight × reps
// and let the main button log a set with one tap (「同上完成」), no sheet
// no keyboard for the typical 5×5 case. Stepper chips only when user
// actually wants to change values.
//
// Resting time is handled by the global PiP overlay (see RootView). This
// view stays visible during rest; user can keep interacting with chips
// or tap 「跳过」 to advance immediately.

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct IPhoneActiveWorkoutView: View {

    @StateObject var controller = IPhoneWorkoutController()
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showFinishConfirm = false

    /// Initial item to load — passed from TodayView's "开始训练" routing.
    let initialTemplateItem: TemplateItemSnapshot?
    let templateId: UUID?

    init(item: TemplateItemSnapshot? = nil, templateId: UUID? = nil) {
        self.initialTemplateItem = item
        self.templateId = templateId
    }

    var body: some View {
        ZStack {
            Tokens.Color.groupedBg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                progressStrip
                ScrollView {
                    VStack(spacing: 12) {
                        currentExerciseCard
                        loggedSetsList
                        Color.clear.frame(height: 100) // bottom CTA spacing
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                Spacer(minLength: 0)
            }
            VStack {
                Spacer()
                bottomCTA
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Avoid re-init when view re-appears (e.g. PiP minimize → expand).
            if controller.exerciseId.isEmpty {
                if let item = initialTemplateItem {
                    controller.preparePlanned(item: item, templateId: templateId)
                } else {
                    controller.prepareAdHoc(exerciseId: "back-squat")
                }
            }
        }
        .confirmationDialog("结束训练？", isPresented: $showFinishConfirm) {
            Button("结束训练", role: .destructive) {
                controller.finishWorkout(context: context)
                dismiss()
            }
            Button("继续训练", role: .cancel) {}
        } message: {
            Text("已完成 \(controller.loggedSets.count) 组")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Tokens.Color.label)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(controller.exerciseDisplayName)
                .font(.system(size: 17, weight: .bold))
            Spacer()
            Button { showFinishConfirm = true } label: {
                Text("结束")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Tokens.Color.danger)
            }
            .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background(.thinMaterial)
    }

    // MARK: - Progress strip

    private var progressStrip: some View {
        let total = max(controller.plannedSpecs.count, controller.loggedSets.count + 1)
        let done = controller.loggedSets.count
        return VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("已完成 \(done) / \(total) 组")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                Spacer()
                if controller.phase == .resting {
                    Text("休息中 \(formatTime(controller.restRemainingSec))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Tokens.Color.accent)
                        .monospacedDigit()
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Tokens.Color.card)
                    RoundedRectangle(cornerRadius: 3).fill(Tokens.Color.accent)
                        .frame(width: max(8, geo.size.width * CGFloat(done) / CGFloat(max(total, 1))))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }

    // MARK: - Current exercise card

    private var currentExerciseCard: some View {
        VStack(spacing: 14) {
            Text("第 \(controller.currentSetIndex + 1) 组")
                .font(.system(size: 12, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(Tokens.Color.accent)
                .padding(.top, 16)

            // Big inline display: 100 kg × 5
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(controller.currentWeightKg))")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("kg")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                Text("×")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .padding(.horizontal, 6)
                Text("\(controller.currentReps)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("reps")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            .foregroundStyle(Tokens.Color.label)

            // ± steppers (chips). Inline, low ceremony — only used when user needs to change.
            HStack(spacing: 10) {
                stepperChip(label: "重量") {
                    HStack(spacing: 6) {
                        chipButton("−2.5") { controller.currentWeightKg = max(0, controller.currentWeightKg - 2.5) }
                        Text("\(formatKg(controller.currentWeightKg)) kg")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .frame(minWidth: 56)
                        chipButton("+2.5") { controller.currentWeightKg = min(500, controller.currentWeightKg + 2.5) }
                    }
                }
                stepperChip(label: "次数") {
                    HStack(spacing: 6) {
                        chipButton("−1") { controller.currentReps = max(1, controller.currentReps - 1) }
                        Text("\(controller.currentReps)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .frame(minWidth: 24)
                        chipButton("+1") { controller.currentReps = min(99, controller.currentReps + 1) }
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func stepperChip<Content: View>(label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .tracking(0.4)
            content()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Tokens.Color.groupedBg, in: RoundedRectangle(cornerRadius: 10))
    }

    private func chipButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(symbol)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Tokens.Color.label)
                .frame(width: 36, height: 28)
                .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logged sets list

    private var loggedSetsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !controller.loggedSets.isEmpty {
                Text("已完成的组")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                    .tracking(0.5)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                ForEach(Array(controller.loggedSets.reversed().enumerated()), id: \.element.id) { (i, set) in
                    HStack(spacing: 10) {
                        Text("#\(controller.loggedSets.count - i)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                            .frame(width: 28, alignment: .leading)
                        Text("\(Int(set.weightKg)) kg × \(set.reps)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Tokens.Color.label)
                            .monospacedDigit()
                        Spacer()
                        if let rpe = set.rpe {
                            Text("RPE \(rpe)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Tokens.Color.secondaryLabel)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Tokens.Color.groupedBg, in: Capsule())
                        }
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Tokens.Color.success)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    if i < controller.loggedSets.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
        }
        .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                switch controller.phase {
                case .ready, .setActive:
                    // Trainer's killer feature: 同上完成 / 完成本组
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        controller.completeCurrentSet()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                            Text(controller.loggedSets.isEmpty ? "完成本组" : "同上完成")
                                .font(.system(size: 17, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Tokens.Color.accent, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Tokens.Color.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)

                case .setEnded, .resting:
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        controller.skipRest()
                    } label: {
                        Text(controller.phase == .resting ? "跳过休息 · \(formatTime(controller.restRemainingSec))" : "进入休息")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Tokens.Color.label)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Tokens.Color.card, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Tokens.Color.accent.opacity(0.5), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)

                case .finished:
                    Color.clear.frame(height: 54)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.thinMaterial)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }

    private func formatKg(_ v: Double) -> String {
        if v.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(v))" }
        return String(format: "%.1f", v)
    }
}
