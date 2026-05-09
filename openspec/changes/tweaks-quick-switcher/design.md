## Context

在 Claude Design 的最后一轮决策里，用户锁定 数据密度=标准、Readiness=圆环 仅留训练目标可切。但切目标的入口不能藏在 Profile 菜单深处，否则用户感受不到"一键改气质"的设计意图。

## Decisions

### D1：bottom sheet 而不是 popover

iPhone 上 popover 有方向限制和锚点别扭。`.sheet(isPresented:)` + `.presentationDetents([.medium, .large])` 给中等高度，刚好显示 5 个目标 + 2 个 lock 行。

### D2：lock 行显示数据密度 / Readiness 风格

Tweaks 哲学要透明：什么被锁、什么能调。两条 lock 行读起来像产品决定的解释，避免用户后续问"为什么没有别的开关"。如果 V2 重新开放，把 lock icon 换成 toggle 即可。

### D3：直接 mutate UserProfile 而不是引入新的 Tweaks model

避免 V2 还得迁移。trainingGoal 已经是 UserProfile.trainingGoalRaw，改完 SwiftData 自动持久化，所有 @Query consumer 立即重渲染，包括 GoalTheme 在每个 view 计算的 accent。

### D4：TweaksButton 放 ScrollView top-trailing overlay

TodayView 用 navigationBarHidden(true) 没法用 toolbar item。overlay alignment .topTrailing 放在最外层 ScrollView 的 frame 上，padding 4/12 让按钮坐落在顶部安全区下方。不挡 TodayHeader（header 内部 padding-top 8，按钮在 4，看起来像漂浮在 header 上方右上角）。

## Risks / Trade-offs

- **Risk**: 在小屏 iPhone SE 上，TweaksButton 可能压到 Readiness ring 的视觉空间。**Mitigation**：按钮 36 pt，ring 96 pt 在右下方距离足够；padding 4/12 已留间距
- **Trade-off**: 不做 popover 形式，但好处是 sheet 视觉更统一

## Open Questions

无。
