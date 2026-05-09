## ADDED Requirements

### Requirement: TweaksButton on TodayView

`TodayView` SHALL render a `TweaksButton` in the top-trailing overlay of its ScrollView. Tapping the button presents `TweaksQuickSwitcher` as a sheet with `[.medium, .large]` detents.

#### Scenario: Tap button opens sheet

- **WHEN** the user taps the slider icon in the top-right corner of TodayView
- **THEN** TweaksQuickSwitcher appears as a medium-detent sheet bound to `profiles.first`

### Requirement: Goal grid persists on tap

The TweaksQuickSwitcher 训练目标 section SHALL list 5 rows (爆发 / 力量 / 增肌 / 减脂 / 综合) each with the goal's accent dot, label, and one-line body. Tapping a row SHALL set `profile.trainingGoal` to that goal, save the context, and provide a selection haptic.

#### Scenario: Switch from strength to power

- **WHEN** the user taps 爆发
- **THEN** profile.trainingGoal becomes .power
- **AND** the row checkmark appears next to 爆发

### Requirement: Whole-app accent recolor on switch

After the user changes goal, every consumer of `GoalTheme.accent(for: profile.trainingGoal)` (TodayView, PlanView CTAs, scheduled banner border, History calendar selection ring, Stats deltas, Onboarding dots) SHALL re-render with the new accent on next view appearance.

#### Scenario: Switch goal then navigate Plan tab

- **WHEN** user switches to 增肌 (purple) and goes to Plan tab
- **THEN** Plan's start chips, sticky CTA, exercise card border all use purple

### Requirement: Locked sub-tweaks shown read-only

The sheet SHALL include two lock rows below 训练目标:

- 数据密度 = 标准 (locked)
- Readiness 风格 = 圆环 (locked)

Each row shows a lock.fill icon, the value, and a one-line body. They are not interactive in V1.

#### Scenario: User cannot toggle 数据密度

- **WHEN** the user taps the 数据密度 row
- **THEN** nothing happens (no state change, no haptic)
