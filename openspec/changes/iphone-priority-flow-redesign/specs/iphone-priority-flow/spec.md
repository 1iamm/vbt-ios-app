## ADDED Requirements

### Requirement: 5-tab main navigation

The iPhone app SHALL present exactly five top-level tabs in this order: 今天, 计划, 历史, 统计, 我的. The TabView accent color tracks the user's TrainingGoal-derived theme.

#### Scenario: Tabs visible on launch after onboarding

- **WHEN** a UserProfile exists and the user enters MainTabsView
- **THEN** five tab items are displayed: 今天 / 计划 / 历史 / 统计 / 我的

### Requirement: Today screen prefers planned content over ad-hoc

The 今天 screen SHALL render content in this priority order:

1. TodayHeader (date + 今天 title + 96 pt Readiness ring + HRV / 睡眠 / RHR strip)
2. **If a DayPlan exists for today**: a "已安排今日" SectionHeader followed by a ScheduledTrainingCard (template name + source + 从 Watch 开始 + 编辑 buttons)
3. AI recommendation horizontal scroll (purple cards) — only if `AIRecommendationEngine.recommendations(context:)` returns at least one
4. "我的模板" list (top 5 templates by updatedAt)
5. "快速起点" 3-up grid (重做上次 / 上周同日 / 空白训练)

The Today screen SHALL NOT show ad-hoc workout content (no "最近训练 = today's workout") unless that content was driven by a DayPlan.

#### Scenario: Today plan exists

- **WHEN** there is a DayPlan whose `date` falls on today and a Template with id `templateId`
- **THEN** the ScheduledTrainingCard appears with the template's name and a `从 Watch 开始` button

#### Scenario: No plan, no templates

- **WHEN** the user has zero templates and zero DayPlans for today
- **THEN** the Today screen still renders the header, an empty-state card prompting "新建模板", and the quick-start tiles

### Requirement: Tapping "从 Watch 开始" pushes the template to Watch

The ScheduledTrainingCard's primary CTA SHALL invoke `TemplateSyncService.push(template:on:)` with the corresponding template and DayPlan.date, then provide success haptic feedback.

#### Scenario: Push succeeds

- **WHEN** the user taps "从 Watch 开始" on the scheduled card
- **THEN** a TemplateSnapshot is encoded and `WCSession.transferUserInfo` is invoked
- **AND** within seconds the Watch's WatchHomeView shows "今日计划：<name>" entry

### Requirement: Single-screen plan editor

The Plan editor (`PlanView`) SHALL be a single scrollable screen that contains:

- A summary header (来源 + 4 stats: 动作 / 组 / 训练量 / 预估)
- A horizontally scrolling start chips strip (重做上次 / 上周同日 / 模板 / PR 重测 / CMJ / 空白)
- A folding exercise list where each card collapses to one line and expands to show:
  - per-set table with 组 / 重量 / 次数 / 休息
  - "+ 正式组" / "+ 热身" / 金字塔 buttons
  - footer row with 目标速度 / VL 警戒
- A bottom sticky CTA bar with three buttons: square Watch icon | 开始训练 (accent, full width) | square calendar icon

#### Scenario: Tap exercise card to expand

- **WHEN** the user taps any folded exercise card
- **THEN** the card expands to show the per-set table for that item
- **AND** all other expanded cards collapse

#### Scenario: Bottom Watch button pushes template

- **WHEN** the user taps the leading Watch icon or the central "开始训练" CTA
- **THEN** `TemplateSyncService.push(template:on:)` is invoked with `plannedDate`
- **AND** a "已推送到 Watch" alert appears

#### Scenario: Bottom calendar button schedules

- **WHEN** the user taps the trailing calendar icon
- **THEN** the `SchedulePlanSheet` opens with date+time pickers and a "同步到 iPhone 日历" toggle

### Requirement: Per-set spec editor

When the user taps a row in the per-set table, a sheet SHALL open allowing edit of:

- kind (warm-up / work)
- weightKg (Stepper, 0.5–500, step 2.5)
- reps (Stepper, 1–30)
- restSeconds (Picker: 0 / 30 / 60 / 75 / 90 / 105 / 120 / 150 / 180 / 210 / 240)

Saving the sheet SHALL persist via SwiftData. A delete row button SHALL remove the spec.

#### Scenario: Edit set saves

- **WHEN** the user changes weight from 100 to 110, taps 完成
- **THEN** the per-set table re-renders with 110 kg

### Requirement: Pyramid template button

Tapping "金字塔" SHALL replace existing work sets (preserving warm-up sets) with 5 work rows at 50%, 70%, 85%, 95%, 100% of the current top-set weight, with reps decreasing by 1 per row.

#### Scenario: Apply pyramid to a 100kg work set

- **WHEN** the item has a single 100 kg work set with 5 reps and the user taps 金字塔
- **THEN** the work-set list becomes [50/5, 70/4, 85/3, 95/2, 100/1] (reps clamped to ≥ 1)

### Requirement: Weekly planner with EventKit sync

The Weekly Planner (`WeeklyPlanView`) SHALL display the current ISO week's 7 days. Each day shows either the assigned template's color bar + name + scheduled time, or a dashed placeholder with "+ 安排训练" / "未训练" / "休息日".

A toggle SHALL request EventKit write-only access on first enable, then create / update / delete events in a "训练" calendar. The DayPlan persists `eventKitIdentifier` so subsequent edits update the same event rather than duplicating.

#### Scenario: Enable sync grants access

- **WHEN** the user toggles "同步到 iPhone 日历" on for the first time
- **THEN** `EventKitService.requestWriteAccess()` is invoked
- **AND** if granted, every existing DayPlan in the visible week writes to the "训练" calendar

#### Scenario: Edit existing scheduled day

- **WHEN** a DayPlan with `eventKitIdentifier` exists and the user changes its time
- **THEN** the existing EKEvent is updated (same identifier), no duplicate created

### Requirement: iOS-native history calendar

The History calendar SHALL render a month grid in iOS Calendar visual language:

- Month title + Mon-first weekday header in system red
- Today rendered as a system-red filled circle with white digit
- Selected non-today day rendered with accent-color border + accent-tinted fill
- Below each digit, up to 3 colored dots:
  - accent dot for completed Workouts
  - velocity-blue dot for JumpTest events
  - system-blue dot for planned-but-not-done DayPlans

Tapping a day SHALL update the selected-day preview card below the calendar.

#### Scenario: Select day with workout

- **WHEN** the user taps a day that has a Workout
- **THEN** a card appears showing the workout's exercise name, 4 stats (时长/总训练量/总组数/均速), tappable to WorkoutDetailView

#### Scenario: Select day with plan only

- **WHEN** the user taps a day that has only a DayPlan (no Workout)
- **THEN** a card appears showing the planned template name + 计划时间 + "计划中" status (in system-blue)

### Requirement: Workout detail with per-exercise folding cards

`WorkoutDetailView` SHALL show:

1. Hero block (weekday + goal label + exercise name + PR badge + 4 stats)
2. "查看综合时间轴" entry that pushes a landscape-rotated chart view
3. Per-exercise folding card with:
   - Header: numbered tile + exercise name + summary (`Nx M @W kg`)
   - Mini sparkline of per-set mean velocity (when ≥ 2 sets exist)
   - Expanded body: table of sets with 组 / 重量 / 次数 / 休息 / 均速 (slow set highlighted in VL color)

#### Scenario: First exercise expanded by default

- **WHEN** the user opens WorkoutDetailView
- **THEN** the first exercise group's card is already expanded

### Requirement: Stats tab headline + e1RM + Readiness trend

`StatsView` SHALL display:

1. **Headline card**: "本周 vs 上周" 4-up grid (训练量 / 训练次数 / 平均速度 / 平均 VL%) with delta percentage; positive volume / count deltas show green, negative MV deltas show red, smaller VL% deltas show green
2. **e1RM list**: top 3 most-frequent exercises with name, latest e1RM, mini sparkline of recent 8 workouts' best-set e1RM (Epley formula `weight × (1 + reps / 30)`), and percent change since first record
3. **Readiness chart**: 14-day line + area chart with system Charts framework
4. **PR list**: latest 5 PersonalRecord rows linking to PRListView

#### Scenario: This week stronger

- **WHEN** thisWeek volume > lastWeek volume by 8%
- **THEN** the 训练量 tile shows the value with "+8%" in green

#### Scenario: Empty state

- **WHEN** there are zero workouts ever
- **THEN** the e1RM section shows "训练数据不足" empty state, the headline tiles all read 0, and Readiness shows "数据建立中"

### Requirement: TemplateItem per-set fallback

When a TemplateItem's `setSpecs` collection is empty, all UI SHALL render the legacy `targetSets × targetReps @ targetWeightKg` shape. When the collection is non-empty, the UI SHALL render rows from `orderedSetSpecs` only and ignore the legacy fields.

#### Scenario: Legacy template

- **WHEN** the user has a TemplateItem with targetSets=3, targetReps=5, targetWeightKg=100, setSpecs=[]
- **THEN** PlanView's collapsed card reads "5×3 @100kg" and the expanded table renders 3 work rows from the legacy params

#### Scenario: Per-set template

- **WHEN** the same TemplateItem has 5 setSpecs (2 warm + 3 work) added by the user
- **THEN** PlanView ignores the legacy targetSets/targetReps/targetWeightKg and renders 5 rows with each spec's weight/reps/rest

### Requirement: TrainingGoal drives accent color

The accent color across all V4 redesign components (chips, CTAs, scheduled banner border, calendar selection ring, color bars in template rows) SHALL come from `GoalTheme.accent(for: profile.trainingGoal)`. Changing trainingGoal in Profile editor SHALL recolor the entire app on next render.

#### Scenario: Switch from strength to power

- **WHEN** the user changes trainingGoal from .strength to .power in ProfileEditorView
- **THEN** all accent UI re-renders in system red on next view appearance

### Requirement: Calendar usage descriptions in Info.plist

The iOS target's Info.plist SHALL include `NSCalendarsWriteOnlyAccessUsageDescription` and `NSCalendarsFullAccessUsageDescription` strings explaining the training-sync purpose. Without these, EventKit calls trap on iOS 17+.

#### Scenario: First sync prompts user

- **WHEN** the user toggles calendar sync ON for the first time
- **THEN** the system displays the description string from `NSCalendarsWriteOnlyAccessUsageDescription`
