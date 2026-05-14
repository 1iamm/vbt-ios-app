// ExportView.swift
// VBTrainer · iPhone · 2026-05
//
// Wires CSVExporter / JSONExporter to UIActivityViewController for sharing.

import SwiftData
import SwiftUI

struct ExportView: View {
    @Environment(\.modelContext) private var context
    @State private var shareItem: ShareableFile?

    var body: some View {
        Form {
            Section("CSV") {
                Button {
                    shareItem = makeCSV()
                } label: {
                    Label("导出全部训练为 CSV", systemImage: "tablecells")
                }
            }

            Section("JSON") {
                Button {
                    shareItem = makeJSON()
                } label: {
                    Label("导出完整数据为 JSON", systemImage: "doc.text")
                }
                Text("包含所有训练、CMJ、Readiness 快照、PR 记录。可用于备份和未来导入。")
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }

            Section {
                Text("导出的数据为你本地的副本，App 不保留导出文件。HealthKit 健康数据（心率/HRV/睡眠/温度）始终在本机处理，**永远不上云**。")
                    .font(Tokens.Font.footnote)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
        }
        .navigationTitle("数据导出")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareItem) { file in
            ShareSheet(items: [file.url])
        }
    }

    private func makeCSV() -> ShareableFile? {
        let workouts = WorkoutStore.all(in: context)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "VBTrainer-\(timestampSuffix()).csv"
        )
        do {
            try CSVExporter.writeFile(workouts: workouts, to: url)
            return ShareableFile(url: url)
        } catch {
            return nil
        }
    }

    private func makeJSON() -> ShareableFile? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "VBTrainer-\(timestampSuffix()).json"
        )
        do {
            try JSONExporter.writeFile(in: context, to: url)
            return ShareableFile(url: url)
        } catch {
            return nil
        }
    }

    private func timestampSuffix() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }
}

struct ShareableFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
