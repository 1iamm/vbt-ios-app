## Context

Claude Design 的 chat 转录里用户的明确诉求：

1. 工具优先级 P0 = 提前规划（≤ 2 屏完成动作计划）；P1 = 历史回看；P2 = 统计环比
2. 主屏不要默认显示训练 — 必须用户已建立训练或已安排过模板才出现
3. 模板支持 **每组独立调**（不同重量、不同次数、不同休息）
4. 历史日历用 iOS 原生样式（红今天 / 圆点事件）
5. 周计划 → iPhone 日历同步（双向，先 V1 单向写入）
6. 计划页参考训记 / Hevy 风格：能折叠的就不要开新页

设计稿（vbt-screens-v4.jsx）也定调了交互细节：折叠动作卡、起点 chips、sticky CTA、每组独立调表。tweaks 默认锁定 数据密度=标准 / Readiness=圆环。

## Goals / Non-Goals

**Goals:**
- 完整落地 V4 5 步主动线 + 5 tabs
- 数据模型支持 per-set 规格 + EventKit 同步用的 DayPlan
- 既有 Watch 训练流程（PR #1 落地）零回归
- 单屏组装：从 "我的模板" 点进去到能开始训练 ≤ 1 步（同一屏的 sticky CTA "开始训练"）

**Non-Goals:**
- AI 真模型推理（V1 只做规则化推荐 stub）
- iOS 日历 → DayPlan 的反向同步（V1.5 工作）
- 综合时间轴重做（双层时间轴 / 离散组带 / 可点击图例）— 留下个 change，本次只把入口接通用既有 ComprehensiveChartView
- 模板分享 / 公开模板库
- iPad split / 大字号 dynamic type 校准

## Decisions

### D1: 主屏的"已安排"判定 — 用 DayPlan 而不是 Workout

主屏 banner 出现的条件：今日 DayPlan 存在且未完成。
不用 "今天有 Workout 完成" 作为判定，因为：
- DayPlan 是 **意图**，Workout 是 **结果**；意图先于结果
- 用户在 PlanView "开始训练" 时还没有 Workout，但应该已经有 DayPlan
- 训练完成后如果 DayPlan.completed = true，banner 就消失（V1.5 实装；V1 不主动 mark completed，让 banner 仅在当天显示）

为减少代码：当前实现下 banner 只看是否有今天的 DayPlan，不看 completed —— 训练完成后用户重开 app 仍能看到 banner，但点击会进 PlanView 显示已经完成的状态。下次 Workout 写入时再 mark DayPlan.completed = true。这是 V1.5 优化点。

### D2: per-set spec 的 fallback

TemplateItem 已有 `targetSets/targetReps/targetWeightKg/restSeconds` 字段。新增 `setSpecs` 关系：
- 当 `setSpecs` 为空 → 视为 "全组同重"，UI 用 `targetSets × targetReps @ targetWeightKg`
- 当 `setSpecs` 非空 → 完全替代旧字段，UI 渲染每行
- "+ 正式组 / + 热身" 按钮第一次按下时把第一个 set 从旧字段灌进 setSpecs（懒迁移）
- "金字塔" 按钮直接生成 5 行 50% / 70% / 85% / 95% / 100% × top weight

Watch 端短期 fallback：`TemplateSyncService` 仍发送旧字段（targetSets / targetReps / targetWeightKg）。Watch 训练时按统一参数走。等下个 change 扩展 TemplateItemSnapshot 加 `[SetSpecSnapshot]?` 后，Watch 才能逐组使用不同重量。

### D3: AI 推荐 = 规则化 stub，不是真 AI

V1 哲学是 "用户自己当教练"。V2 才接 AI。但设计稿要求今天主屏有 "AI 推荐" 紫色卡。折中：
- 用本地数据驱动的 3 条规则（Readiness 低 / 距上次 PR 远 / 距上次 CMJ 远）
- 卡的视觉、紫色、"为何推荐 →" action label 全部按设计稿复刻
- 函数签名 `AIRecommendationEngine.recommendations(context:) -> [AIRecommendation]` 后续 V2 直接换实现

### D4: EventKit 同步 = write-only + 独立"训练"日历

iOS 17+ 支持 `requestWriteOnlyAccessToEvents`，比 full access 摩擦更小。
独立日历的好处：用户能随时关掉整列而不污染日常日历视觉；便于反向查询（V1.5 时按 `calendarIdentifier` 过滤）。

写入约定：
- title: `训练 · <模板名>`
- start = DayPlan.date 的 startOfDay + scheduledTimeMinutes
- duration = 60 min（V1 固定，V1.5 用模板预估时长）
- alarm: -30 min
- notes: `VBTrainer 自动生成 · 共 N 个动作`
- DayPlan 保存 `eventKitIdentifier` 用于后续更新 / 删除

### D5: 历史日历 = 我们自己画，不嵌 iOS Calendar

设计稿要求 "iOS 原生日历样式"，但不是嵌系统日历视图。原因：
- 我们要在格子下方绘制多色事件圆点（done / planned / cmj），系统视图给的样式不可定制
- 选中态（accent 描边圆）也不是系统行为
- 周一作为首列（非默认 Sunday）

实现：`IOSCalendarMonth` view 自己画格子，沿用 iOS 视觉语言（红今天圆 / 红色月标题与翻月箭头 / 红 6×6 圆居中分隔）。

### D6: 5 tabs vs 4 tabs vs 把 Profile 隐到右上角

设计稿提到 "5 步主动线"，但 "开练" 是 Watch。iPhone tabs 实际是 4 个用户能直接进的页面 + 1 个设置。
3 个选择：
- A) 4 tabs：今天 / 计划 / 历史 / 统计；Profile 收到右上角
- B) 5 tabs：今天 / 计划 / 历史 / 统计 / 我的
- C) 5 tabs 但 "我的" 改成 "更多"

选 B 因为：
- iOS 5 tab 是常见模式（系统支持，无需额外 nav）
- "我的" 含 Onboarding 修改、Citations、Export，访问频率不高但需要稳定入口
- 不必折腾 iPhone 的右上角，让 Today header 安静

### D7: WorkoutDetailView "查看综合时间轴" 入口 — 旋转既有视图

设计稿要求横屏综合时间轴重做，但本 change 范围已大。最小可工作版：用 GeometryReader 旋转 90 度展示既有 `ComprehensiveChartView`。下次 change 重做：双层时间轴（绝对 + 相对）/ 离散组带 / 可点击隐藏数据系列。

## Risks / Trade-offs

- **Risk**: SwiftData schema 加新表会触发隐式迁移；测试机首次启动可能慢一两秒。**Mitigation**: 仅新增表（不改字段），SwiftData 默认 lightweight migration 应该秒级
- **Risk**: 用户拒绝日历授权 → schedule sheet 调 EventKit 报 accessDenied。**Mitigation**: SchedulePlanSheet 已捕获错误并显示 "未授权日历访问"；DayPlan 仍写入本地，仅日历同步失败
- **Risk**: TemplateSnapshot 协议没扩展，Watch 上多组训练时仍用旧 targetSets/Reps，per-set spec 不传过去。**Trade-off**: 本 change 接受这个限制，下个 change 扩展协议。当前用户在 Plan 编辑器里看到的是真实 per-set 数据，进 Watch 训练时回退到第一组工作集参数 — 仍然能完成训练，只是 Watch 上不区分每组重量
- **Trade-off**: AI 推荐用规则化 stub。用户需要被告知（design.md 写明），但 UI 上不暴露 "这是规则" 的字眼，遵循设计稿语气
- **Trade-off**: TabView 5 tab 在小屏上 label 略挤；用 SF Symbol 简化，可接受

## Migration Plan

- 新增模型 → SwiftData lightweight migration 自动处理
- 旧 `@AppStorage("vbt.dayPlanMap")` JSON 不主动迁移到 DayPlan（user 数据小，让用户自己重新 schedule）。下次 change 写一个一次性迁移函数
- 旧 TemplateItem 的 setSpecs 默认空 → UI 自动 fallback 到旧字段；用户进 Plan 编辑器 → 第一次按 "+ 正式组 / 热身" 时灌入 setSpecs

## Open Questions

- **VL 警戒线触发后**：Watch 已经会发 `.vlCeilingExceeded`，UI 还没消费（warm-up 流程的 TODO）。本 change 不做
- **iPhone 日历事件双向编辑**：用户在日历 App 改时间 → DayPlan 跟着改？V1.5 用 `EKEventStoreChanged` 通知 + 同步任务做
- **Tweaks 全面接入**：当前只用 TrainingGoal → 主色。数据密度 / Readiness 风格 在 PRD 里有但本次 UI 没接（按用户最终决定锁定为标准 / 圆环）。如果未来要让用户切换，需在 Settings 里加 Picker
