## ADDED Requirements

### Requirement: 4-step flow

`OnboardingView` SHALL have exactly 4 steps in this order: 欢迎 / 价值主张 / HealthKit 授权 / 个人画像. After step 4 the "开始使用" CTA creates the UserProfile and calls `onCompleted`.

#### Scenario: Going forward through all steps

- **WHEN** the user taps 继续 four times
- **THEN** the screens cycle 0→1→2→3 and "开始使用" appears on screen 3
- **AND** tapping "开始使用" persists a UserProfile and dismisses Onboarding

### Requirement: Top progress dots

A row of 4 capsule dots SHALL appear at the top. The dot at the current `step` is wider (≈22 pt) and uses the accent color; passed dots use accent at full saturation; future dots use Tokens.Color.fill.

#### Scenario: On step 2

- **WHEN** step == 1 (价值主张)
- **THEN** the second dot is wide and accent-colored
- **AND** the first is accent narrow; the third and fourth are fill-colored

### Requirement: Goal-driven accent

Accent color used by dots / CTA / hero glow SHALL come from `GoalTheme.accent(for: goal)`. Changing the goal Picker on step 4 SHALL re-render with the new accent immediately.

#### Scenario: Switch goal from strength to power

- **WHEN** user changes goal Picker to power on step 4
- **THEN** dots / CTA / accents render in system red

### Requirement: Step transitions animated

Forward and back transitions SHALL use `.move(edge: .trailing/.leading).combined(with: .opacity)` with default easeInOut(0.22). The progress dot width animates with `.easeInOut(0.2)`.

### Requirement: Personal profile single screen

Step 4 SHALL contain two field groups (基础 / 训练背景) inside a single ScrollView. 基础 includes 年龄 (Stepper) / 性别 / 身高 / 体重. 训练背景 includes 体型 / 经验 / 目标. All three pickers use `.segmented` style.

#### Scenario: Goal change updates dots accent

- **WHEN** user picks a goal from segmented control
- **THEN** the dots strip color changes within the same animation frame

### Requirement: Bottom CTA layout

The footer SHALL contain (from leading): a circular back button (chevron.left, 48pt circle, fill background) — only visible when `step > 0` — and a wide accent-colored capsule CTA labeled "继续" (or "开始使用" on the last step) with an accent-tinted shadow.
