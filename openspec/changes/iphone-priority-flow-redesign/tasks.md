## 1. 数据模型 + 配置

- [x] 1.1 新增 `Shared/Models/DayPlan.swift`
- [x] 1.2 新增 `Shared/Models/TemplateSetSpec.swift` + 扩展 `TemplateItem` 加 `setSpecs` 关系 + 计算属性
- [x] 1.3 改 `Shared/Models/ModelSchema.swift` 注册 DayPlan + TemplateSetSpec
- [x] 1.4 改 `project.yml` 加 `INFOPLIST_KEY_NSCalendarsWriteOnlyAccessUsageDescription` + `NSCalendarsFullAccessUsageDescription`

## 2. 服务层

- [x] 2.1 新增 `Shared/Services/DayPlanStore.swift`（CRUD + 区间查询）
- [x] 2.2 新增 `Shared/Services/AIRecommendationEngine.swift`（3 条规则）
- [x] 2.3 新增 `Shared/Services/EventKitService.swift`（write-only access + 训练日历）
- [x] 2.4 新增 `Shared/Services/WeekOverWeekStats.swift`
- [x] 2.5 新增 `Shared/Theme/GoalTheme.swift`（goal → accent + 默认 VL）

## 3. 共享 UI

- [x] 3.1 新增 `VBTrainer/Views/Common/RedesignComponents.swift`：TodayHeader / SectionHeader / ScheduledTrainingCard / TemplateRowItem / AIRecommendationCard / QuickStartTile / MiniSparkline / IOSCalendarMonth / StartChipsBar
- [x] 3.2 提取 `VBTrainer/Views/Common/ExercisePickerSheet.swift`

## 4. Tab 重组

- [x] 4.1 改 `RootView.swift`：4 tabs → 5 tabs（今天 / 计划 / 历史 / 统计 / 我的）
- [x] 4.2 删除旧 `Train/` 子目录（PlansView / CalendarPlanView / TemplateEditorView / TemplateItemEditorView）
- [x] 4.3 删除旧 `Today/ReadinessRingCard.swift / WorkoutSummaryCard.swift / TrainingHeatmap.swift`

## 5. Today

- [x] 5.1 重写 `Today/TodayView.swift`：TodayHeader + 已安排 banner（DayPlan-driven）+ AI 推荐 + 我的模板 + 快速起点
- [x] 5.2 "从 Watch 开始" 调用 `TemplateSyncService.push`
- [x] 5.3 新建模板 → 创建 Template + push 到 PlanView

## 6. 计划

- [x] 6.1 新建 `Plan/PlansListView.swift`（顶层模板列表 + 周计划入口）
- [x] 6.2 新建 `Plan/PlanView.swift`（单屏组装：summary + chips + 折叠卡 + per-set 表 + sticky CTA）
- [x] 6.3 新建 `Plan/WeeklyPlanView.swift`（7 天计划 + EventKit 同步）
- [x] 6.4 SetSpecEditorSheet（Stepper / Picker 编辑组）
- [x] 6.5 SchedulePlanSheet（保存 DayPlan + EventKit upsert + Watch push）
- [x] 6.6 DayTemplatePickerSheet（从 Weekly 直接 assign）

## 7. 历史

- [x] 7.1 重写 `History/HistoryView.swift`：iOS 原生日历样式 + segmented (日历/列表/动作) + sync banner
- [x] 7.2 重写 `History/WorkoutDetailView.swift`：hero + 综合时间轴入口 + 每动作折叠卡 + mini sparkline
- [x] 7.3 ComprehensiveTimelineLandscape wrapper（暂时旋转既有图表）

## 8. 统计

- [x] 8.1 新建 `Stats/StatsView.swift`：周环比头条 + e1RM top3 + Readiness 14 天 Charts + PR 列表

## 9. 编译与收尾（用户在 macOS 本机执行）

- [ ] 9.1 跑 `xcodegen generate`（pick up 新 .swift 文件 + 新 INFOPLIST keys）
- [ ] 9.2 编译 iOS target → BUILD SUCCEEDED
- [ ] 9.3 编译 Watch target → BUILD SUCCEEDED（不应有变化）
- [ ] 9.4 真机验证：
  - 进 Today → 看到 96pt Readiness ring + 三联指标
  - 进 计划 → 创建/打开模板 → 添加动作 → 展开 → "+ 正式组" → 编辑组（Stepper 改重量/次数）→ "金字塔" 应用
  - 计划 → 周计划 → 开同步 → 弹日历授权 → 同意 → 检查 iPhone 日历 App 出现 "训练" 日历
  - Today 模板点击 → PlanView → 底部 Watch 按钮 → 弹 "已推送到 Watch"
  - Watch 上 VBTrainer 主屏出现 "今日计划：..."
  - 历史 → 月历样式像 iOS 日历 → 点已练日 → 出预览卡 → 点进详情 → 看到每动作折叠 + mini sparkline
  - 统计 → 周环比 4 宫格 + e1RM 3 行 + Readiness 折线
- [x] 9.5 OpenSpec 文档（proposal/design/spec/tasks）完成
