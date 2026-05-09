## Context

Workout / WorkoutSnapshot 的 rpe/notes 字段从 V1 schema design 起就预留，但前端从未采集过。本 change 把"训练完成那一秒"做成数据采集的最后一步。

## Decisions

### D1：Watch 上只采 RPE + 3 选 1 情绪 tag，不接键盘笔记

watchOS 没有可用的全键盘体验。设计：
- RPE = 数字表冠（1-10）+ 视觉色彩（绿/橙/红 渐变）+ 文字标签
- 情绪 tag = "强 / 正常 / 拉胯" 三选一，写入 `notes` 字段为 "感受：正常"
- 详细笔记必须回 iPhone 补 — 详情页一键补写

理由：完赛屏多一个键盘 = 完赛率掉 5%+，不可接受。Watch 只采 1 tap 数据。

### D2：默认 RPE = 7

学术中位数 + 实践观察：力量训练大多在 RPE 6-8 之间，7 是真实众数。让用户什么都不调就按"完成" 也能落地有效数据，不强迫思考。极端值（1-3 或 9-10）才需要主动调整。

### D3：completeWithFeedback 而非新参数 complete(rpe:notes:)

新方法名让"提供反馈"成为显式动作。原 `complete()` 保留 backward-compat（内部转调 `completeWithFeedback(rpe: nil, notes: nil)`），方便未来其他完成路径不忘填字段。

`WorkoutSnapshot.rpe / notes` 是 `public var`，直接 mutate 即可，不需要重建 snapshot。

### D4：iPhone 详情页"+ 补写感受" 入口

未填 RPE/notes 的工作集（包括 V1.5 之前训练的所有历史）显式提示补写而不是隐藏。这创造一个**复盘行为**：用户翻历史时主动给老训练添加 RPE，丰富 V2 AI 训练样本。

预设 6 个 tag chip（"状态好 / 状态一般 / 技术问题 / 腰累 / 腿沉 / 心率高"）让点击补充比打字快 5 倍。

### D5：RPE 视觉色阶映射

```
1-4 → success 绿
5-7 → accent 橙
8-9 → warning 橙红
10  → danger 红
```

让用户一眼能从训练历史的 RPE 圆环徽章颜色判断"这周练得猛不猛"，配合 dot 强度差异化（PM agent F 项的 partial 实现）。

## Risks / Trade-offs

- **Risk**: 用户每次都接受默认 7，数据没有真信号。**Mitigation**: 表冠操作物理摩擦低；设计上要把 RPE 屏放在数字结果 stat 之后，让用户对比组数 / 速度数据后再选 RPE
- **Trade-off**: notes 在 Watch 仅 3 选 1 — 真有故事的训练（"今天右肩疼"）只能回 iPhone 补。可接受
- **Risk**: 老 Workout 没 RPE，Stats 算 avgRPE 时分母不准。**Mitigation**: 仅用最近 N 天 + filter rpe != nil

## Open Questions

- 是否给 Stats narrativeLine 接入 avgRPE？（M 接近完成后 Round 4 polish 时做，本 change 不做）
- 是否在 CelebrationCard.generic body 加一行 "今日 RPE X"？（agent 提到，当前不做以保持 generic 简洁）
