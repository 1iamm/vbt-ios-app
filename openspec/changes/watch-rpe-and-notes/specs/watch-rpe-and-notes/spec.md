## ADDED Requirements

### Requirement: Watch summary screen captures RPE

`WatchSummaryView` SHALL include an RPE row with:
- A large digit (38pt rounded bold) bound to digital crown rotation in `[1, 10]` step 1
- Color that transitions: 1-4 success, 5-7 default, 8-9 warning, 10 danger
- A short label below ("极轻" / "中" / "重" / "极限" etc.)
- Default initial value = 7

#### Scenario: User scrolls crown to set RPE 9

- **WHEN** the user rotates the digital crown 4 clicks up from default
- **THEN** the digit shows 9 and the label reads "极重"
- **AND** the digit's color is warning

### Requirement: Three-way feeling tag

The summary screen SHALL include a 3-button row "强 / 正常 / 拉胯" (default 正常). Tapping selects exactly one. The selection's raw label is composed into the snapshot's `notes` field as `"感受：<value>"`.

### Requirement: completeWithFeedback method

`LiveWorkoutController.completeWithFeedback(rpe: Int?, notes: String?)` SHALL:
- await `session.complete()` to obtain the snapshot
- mutate `snapshot.rpe = rpe` if non-nil
- mutate `snapshot.notes = notes` if non-nil and non-empty
- otherwise behave identically to `complete()`

#### Scenario: Default 7 + 正常 feeling

- **WHEN** user taps 完成 with rpe=7 and feeling=正常
- **THEN** the resulting snapshot has rpe=7 and notes=="感受：正常"

### Requirement: iPhone WorkoutDetail displays feedback

`WorkoutDetailView` SHALL render a `feedbackCard` between the hero block
and the "查看综合时间轴" entry. When the workout has rpe or notes, render:

- RPE ring badge (38×38pt) showing the integer and a trim-to-rpe arc colored per the same 4-step scale
- Title row "RPE N · <label>" + notes preview (lines clamped to 2)
- Trailing pencil icon

When neither field is filled, render a single "+ 补写感受 · RPE / 笔记"
prompt in accent color.

#### Scenario: Old workout with no RPE

- **WHEN** the user opens a 6-month-old workout
- **THEN** the feedbackCard reads "+ 补写感受" and tapping opens the editor

### Requirement: Feedback editor sheet

The editor sheet SHALL contain:
- An RPE Slider (1-10 step 1) with the current value rendered as a 36pt digit and a contextual label
- A multi-line `TextField` for free-form notes (3-6 lines)
- A horizontal scroll of 6 preset tag chips: "状态好 / 状态一般 / 技术问题 / 腰累 / 腿沉 / 心率高". Tapping a chip appends `· <tag>` to notes (deduped)
- A "保存" toolbar button that writes to the bound Workout via `try? context.save()`

#### Scenario: Tapping a preset tag appends but doesn't duplicate

- **WHEN** notes is "状态好" and user taps "腰累"
- **THEN** notes becomes "状态好 · 腰累"
- **WHEN** user taps "腰累" again
- **THEN** notes is unchanged
