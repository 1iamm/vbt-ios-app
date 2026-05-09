## Context

V4 设计稿明确要求时间轴重做。SwiftUI Charts 框架原生不支持双层 X 轴 label，也不容易做"按组离散色块"的 overlay，但提供了 `chartOverlay { proxy in ... }` 入口可以拿到 plot 区域几何信息自己绘制。

## Decisions

### D1：单 Y 轴域，将 m/s 映射到 BPM 空间

为什么不用双 Y 轴：Charts 框架的双 Y 轴需要每个 mark 单独配 axis，会让 RuleMark/PointMark 的 series 标识冲突。简单办法是固定 Y 域 40..220（BPM），把 m/s 0..1.5 线性映射到同一个数轴：

```
v_bpm = 40 + min(1.5, max(0, v)) / 1.5 * 180
```

右侧 axis label 渲染对应 m/s 值。视觉等价，实现简单。

### D2：组带在 `chartOverlay` 上方绘制

`proxy.position(forX: date)` 给出每个时间点的 X 坐标。组带绘制：
- 每个 set: x = position(forX: firstRep.timestamp)，宽度 = position(forX: lastRep.timestamp) - x
- 同动作不同色由 `exerciseColorMap` 决定（数据 palette 5 色 + 3 备用 = 8 色循环）
- 同动作的相邻组保留之间留白（自然，因为 firstRep > lastRepPrev）
- 首次出现的动作上方加 small-caps 名字（`if i == 0 || prev.exerciseId != current.exerciseId`）

### D3：双层 X 轴用 GeometryReader 自绘

Charts 的 `AxisValueLabel { ... }` 的 closure 体可以放任意 SwiftUI 视图，但对 `position` 的精细控制有限（会被 Charts 自身的 stride 干扰）。直接用 GeometryReader 5 等分采样：

```swift
ForEach(0..<5) { i in
    let frac = Double(i) / 4.0
    let date = start + total * frac
    VStack { Text(absoluteHHMM(date)); Text("+\(Int(total*frac/60))m") }
        .position(x: width * frac, y: 14)
}
```

5 个 tick 对短训练（30 min）和长训练（90 min）都够用。

### D4：图例点击切换 = `@State Bool` + 条件渲染 mark

每个系列由独立 `@State var showHR/Velocity/VL` 控制。`Chart { if showHR { ... } }` 让 Charts 不渲染对应 series。同时右侧 m/s axis label 在 `showVelocity == false` 时灰化提示。

### D5：VL% 虚线只画"段"

V4 设计要求"VL 25% 改成段状虚线 — 只在每组的色带正下方画一截"。实现：每个 set 算自己的 vl = (V_first - V_last) / V_first * 100；映射到 velocity 域的纵坐标（vl=0 → 1.20 m/s，vl=50 → 0.30 m/s 的线性插值），在 set 的时间区间画一段 LineMark with dashed style。每段独立 series 标识防止 Charts 把它们连成长虚线。

## Risks / Trade-offs

- **Risk**: 共轴映射让用户难以分辨"40 BPM" vs "0 m/s"。**Mitigation**: 左轴标 BPM，右轴标 m/s；图例颜色严格区分（HR=系统红 / Velocity=蓝 / VL=紫）
- **Risk**: 组带 overlay 在 Charts 重新布局时可能错位。**Mitigation**: padding(.top, 30) 给组带预留空间；chartOverlay 的 proxy 提供准确 plot 几何
- **Trade-off**: 不做横屏专属布局（仍由 `ComprehensiveTimelineLandscape` wrapper 旋转 90 度）— 旋转的 wrapper 仍能看清，下个迭代再做"原生横屏布局"

## Open Questions
- 多动作 workout（V1 当前一个 workout = 一个 exerciseId）下的组带颜色切换在 V1 完整不会触发。等 plan-execution 落地后会自然生效。
