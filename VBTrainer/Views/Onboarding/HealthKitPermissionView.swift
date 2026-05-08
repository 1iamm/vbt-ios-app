// HealthKitPermissionView.swift
// VBTrainer · iPhone · 2026-05
//
// Step 2 of onboarding. The actual permission request happens in
// Proposal 7's HealthKitService; this view just explains and triggers.

import SwiftUI

#if canImport(HealthKit)
import HealthKit
#endif

struct HealthKitPermissionView: View {

    @State private var requestedPermission = false

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xl) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 56))
                .foregroundStyle(Tokens.Color.Data.heartRate)
                .frame(maxWidth: .infinity)

            Text("健康数据权限")
                .font(Tokens.Font.title)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: Tokens.Space.md) {
                bullet("心率", subtitle: "训练中实时监控 + 训练前 7 日基线")
                bullet("HRV / RHR", subtitle: "训练前身体准备度评估")
                bullet("睡眠时长", subtitle: "评估是否得到充分恢复")
                bullet("手腕温度", subtitle: "观测身体异常信号")
            }

            Text("所有数据仅在你的设备上处理，VBTrainer 不会上传任何健康数据到服务器。")
                .font(Tokens.Font.footnote)
                .foregroundStyle(Tokens.Color.secondaryLabel)

            Button {
                Task { await requestPermission() }
            } label: {
                Text(requestedPermission ? "已请求权限" : "授予权限")
                    .font(Tokens.Font.headline)
                    .padding(.vertical, Tokens.Space.sm)
                    .frame(maxWidth: .infinity)
                    .background(Tokens.Color.accent.opacity(requestedPermission ? 0.3 : 1.0), in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(requestedPermission)
        }
    }

    private func bullet(_ title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Space.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Tokens.Color.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Tokens.Font.headline)
                Text(subtitle).font(Tokens.Font.footnote).foregroundStyle(Tokens.Color.secondaryLabel)
            }
        }
    }

    private func requestPermission() async {
        #if canImport(HealthKit)
        let store = HKHealthStore()
        var read: Set<HKObjectType> = []
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { read.insert(hr) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { read.insert(hrv) }
        if let rhr = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { read.insert(rhr) }
        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) { read.insert(respiratoryRate) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { read.insert(sleep) }
        if #available(iOS 17.0, *) {
            if let temp = HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature) { read.insert(temp) }
        }
        try? await store.requestAuthorization(toShare: [], read: read)
        #endif
        requestedPermission = true
    }
}
