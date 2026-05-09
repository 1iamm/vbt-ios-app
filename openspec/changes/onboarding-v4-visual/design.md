## Context

V1 Onboarding 是 5 屏 form-based（welcome / HealthKit / basics / background / completion）。设计稿是 4 屏，且视觉做杂志感大字 + 进度 dots + 渐变 hero。

## Decisions

### D1：合并 basics + background 为一屏 "个人画像"

5 → 4 屏的取舍点。基础 4 字段（年龄/性别/身高/体重）+ 背景 3 字段（体型/经验/目标）共 7 字段，单屏 ScrollView 可承接，避免分页。

### D2：欢迎与价值主张拆为两屏

设计稿拆成 onb-1 和 onb-2 各一屏。理由：欢迎屏强调情绪（大字 + 渐变 hero），价值主张屏强调说服（3 行 fact），节奏不同。

### D3：accent 色绑 trainingGoal，最后一屏选目标即时刷整个 onboarding

GoalTheme.accent(for:) 依赖 goal state；body 计算属性 `var accent: Color { GoalTheme.accent(for: goal) }`。改 goal Picker 即重渲染整个 view，dots 颜色 / CTA / hero 渐变都跟着切。"切换是即时的" 跟 Tweaks 设计哲学一致。

### D4：取消 completion 屏

V1 第 5 屏是"一切就绪"装饰屏。删掉 — 用户已经看到 progress dots 满了，"开始使用" CTA 直接退出 onboarding 进 RootView。少一屏更短动线。

## Risks / Trade-offs

- **Risk**: 字段集中到一屏可能高度不够（小屏 iPhone SE）。**Mitigation**：用 ScrollView 包；字段间距紧凑
- **Trade-off**: HealthKitPermissionView 沿用 V1 样式（不重做），与新视觉略不协调。下个 change 可以做但本次 OOS

## Open Questions

无。
