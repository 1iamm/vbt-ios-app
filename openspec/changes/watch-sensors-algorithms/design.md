## Context

Apple Watch 手腕戴位置的 IMU 已被学术验证可用于 VBT 测量（Balshaw 2023，ICC > 0.9，误差 ±0.05-0.10 m/s）。watchOS 上的关键约束：
- 必须开 `HKWorkoutSession`，否则 CMMotion 会被降频（Apple 官方限制）
- 100Hz 采样在 Series 7+ 稳定；电量考虑下不开陀螺仪辐射估计
- 训练时屏幕常亮，主线程不能阻塞

## Goals / Non-Goals

**Goals:**
- 100Hz IMU 稳定采集，零丢帧
- Rep 识别准确率 ≥ 95%（合成数据测）
- 速度计算误差 ≤ 0.10 m/s 跨整组（合成数据测；真机后续校准）
- 全部算法纯函数，可独立单测，不依赖 SwiftData / UI / 真机

**Non-Goals:**
- 不实现真机校准的精确度调优（V2 收集真实数据后再迭代）
- 不写存数据库的代码（Proposal 4）
- 不写 UI（Proposal 3）
- 不实现震动播放（属 UI 层）

## Decisions

### D1: Sensor → Stream 模型

`MotionManager` 输出 `AsyncStream<MotionSample>`，每个 sample 含：
```swift
struct MotionSample {
    let timestamp: TimeInterval   // monotonic
    let userAccel: SIMD3<Double>  // m/s^2, 已去除重力
    let attitude: simd_quatd      // 设备朝向四元数
}
```

理由：
- AsyncStream 自然处理背压、cancellation
- 算法消费者用 `for await sample in stream` 写起来线性
- 解耦传感器与算法，方便单测注入合成流

### D2: Rep 识别——基于垂直加速度的状态机

```
rest ─── userAccel.z 持续向下 ──▶ eccentric
eccentric ─── 速度过零 ──▶ bottom（短暂停留）
bottom ─── userAccel.z 持续向上 ──▶ concentric
concentric ─── 速度过零 ──▶ top
top ─── 静止 ≥ 200ms ──▶ rest（一个 rep 完成）
```

- 引用：O'Reilly 2018（review，state machine 是行业惯例）
- 阈值：每个状态有最小停留时长 + 加速度阈值，避免抖动误判
- ZUPT 时机：进 rest 时强制速度归零

### D3: 速度计算——梯形积分 + ZUPT

```swift
v[t+1] = v[t] + (a[t] + a[t+1]) / 2 * dt   // 梯形积分
if isStaticState() { v[t+1] = 0 }          // ZUPT
```

- 引用：Skog 2010，Foxlin 2005
- 只在 z 轴积分（杠铃运动主要垂直）
- 每 rep 起止时归零，误差不跨 rep 累积

### D4: MV / PV / MPV 计算

每个 rep 结束时基于该 rep 内的速度序列计算：
- MV = ∫v dt / Δt（concentric 阶段的平均速度）
- PV = max(v) over concentric
- MPV = ∫v dt over (concentric where a > 0) / 时长（推进相均速）

引用：Sánchez-Medina 2010 Propulsive。

### D5: VL% 计算

```swift
VL%[i] = (V[1] - V[i]) / V[1] * 100
```

实时计算（每 rep 完成后更新），用 set 配置的 velocityVariant（MV/MPV/PV）取值。

引用：Sánchez-Medina 2011。

### D6: CMJ 跳跃高度

飞行时间法：
```swift
height_meters = g * t_flight^2 / 8
```
其中 `t_flight` = 起跳到落地的时间（基于垂直加速度过零检测）。
引用：Linthorne 2001，Claudino 2017。

精度有限（手腕戴非脚踏式），但用于"今日 vs 基线"对比足够。

### D7: 测试策略——合成 IMU 信号

写一个 `SyntheticMotionGenerator`：给定 rep 数 / 每 rep 速度峰值 / 噪声水平，生成对应的 `userAccel.z(t)` 信号。算法消费这个信号，断言计算出的 rep 数 / 速度等于输入参数（容差 ≤ 5%）。

理由：
- 真机 IMU 测试需要真人做深蹲，单测不能依赖
- 合成信号让算法回归测试自动化
- 真机校准在 V1 末通过用户数据迭代

## Risks / Trade-offs

- **Risk**: 100Hz CMMotion 在低电量模式下被系统强制降频 → **Mitigation**: HKWorkoutSession 开后系统不会降，文档化要求"训练前充电≥20%"
- **Risk**: 状态机阈值过于严格→漏 rep；过松→误识别 → **Mitigation**: 阈值化为可配置常量，用 50+ 合成场景回归
- **Risk**: 手腕加速度噪声大于杠铃直接绑 → **Mitigation**: 用低通滤波（截止频率 10Hz）平滑，引用 Apple Watch 论文证明可行
- **Trade-off**: V1 不做加速度计 + 陀螺仪融合（Madgwick filter），仅用 CoreMotion 已经融合的 `userAcceleration` → 可接受，CoreMotion 已经做了 sensor fusion

## Migration Plan

无（首次实现）。

## Open Questions

- **Watch Series 7 和 9 加速度计响应曲线差异**：V1 不区分，统一用 100Hz；真机数据收集后看是否需要 per-series 校准
