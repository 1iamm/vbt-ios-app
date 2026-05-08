// ProfileView.swift
// VBTrainer · iPhone · 2026-05

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                if let p = profile {
                    Section {
                        NavigationLink {
                            ProfileEditorView(profile: p)
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Tokens.Color.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(zhSex(p.sex))
                                        .font(Tokens.Font.headline)
                                    Text("\(p.age) 岁 · \(Int(p.heightCm)) cm · \(Int(p.weightKg)) kg")
                                        .font(Tokens.Font.footnote)
                                        .foregroundStyle(Tokens.Color.secondaryLabel)
                                }
                            }
                        }
                    } header: {
                        Text("个人资料")
                    }

                    Section {
                        NavigationLink("训练设置") { SettingsView(profile: p) }
                        NavigationLink("个人记录 PR") { PRListView() }
                    }
                }

                Section("数据") {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("导出训练数据", systemImage: "square.and.arrow.up")
                    }
                }

                Section("隐私") {
                    Text("所有训练、心率、HRV、睡眠数据 **仅存储在你的设备上**。VBTrainer 不上传任何数据到服务器。")
                        .font(Tokens.Font.footnote)
                        .foregroundStyle(Tokens.Color.secondaryLabel)
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("0.1.0").foregroundStyle(Tokens.Color.secondaryLabel)
                    }
                    NavigationLink("引用论文") { CitationsListView() }
                }
            }
            .navigationTitle("我的")
        }
    }

    private func zhSex(_ s: Sex) -> String {
        switch s {
        case .male:   return "男"
        case .female: return "女"
        case .other:  return "其他"
        }
    }
}
