## Context

V1 末打磨。

## Goals / Non-Goals

**Goals:**
- 用户能从 ProfileView 导出 CSV / JSON 单击调出 ShareSheet
- README 体现所有 10 个 proposal 完成状态
- 全部 target 编译通过

**Non-Goals:**
- 不优化具体动效细节（V2 与设计同学一起优化）

## Decisions

### D1: 文件位置

导出文件写入 NSTemporaryDirectory，再用 `UIActivityViewController` 让用户选目的地（AirDrop / 邮件 / 文件 App）。

### D2: 数据范围

- CSV：每行 = 一个 rep（最容易处理）
- JSON：嵌套结构，含 workouts / sets / reps / heartRate / readiness / jumpTests

不导出原始 IMU（V1 不存）。
