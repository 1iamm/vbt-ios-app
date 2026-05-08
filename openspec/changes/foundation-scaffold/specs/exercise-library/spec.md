## ADDED Requirements

### Requirement: 30 个动作元数据

The system SHALL define a constant array `exerciseLibrary: [Exercise]` of length 30 in `Shared/ExerciseLibrary/ExerciseLibrary.swift`. The 30 exercises MUST cover the categories listed below.

Barbell (16):
- `back-squat` (深蹲)
- `front-squat` (前蹲)
- `high-bar-squat` (高杠深蹲)
- `low-bar-squat` (低杠深蹲)
- `bench-press` (卧推)
- `incline-bench-press` (上斜卧推)
- `decline-bench-press` (下斜卧推)
- `close-grip-bench-press` (窄距卧推)
- `deadlift` (硬拉)
- `sumo-deadlift` (相扑硬拉)
- `romanian-deadlift` (罗马尼亚硬拉)
- `standing-overhead-press` (站姿肩推)
- `seated-overhead-press` (坐姿肩推)
- `push-press` (借力推)
- `barbell-row` (杠铃划船)
- `barbell-curl` (杠铃弯举)

Dumbbell (6):
- `dumbbell-press` (哑铃推举)
- `dumbbell-fly` (哑铃飞鸟)
- `dumbbell-row` (哑铃划船)
- `dumbbell-curl` (哑铃弯举)
- `dumbbell-shoulder-press` (哑铃肩推)
- `bulgarian-split-squat` (保加利亚分腿蹲)  — `side` defaults to `.left/.right` per set

Bodyweight / Machine (8):
- `pull-up` (引体向上)
- `push-up` (俯卧撑)
- `air-squat` (自重深蹲)
- `dip` (双杠臂屈伸)
- `lat-pulldown` (高位下拉)
- `seated-row` (坐姿划船)
- `leg-press` (腿举)
- `cmj` (CMJ 跳跃) — special: equipment is none, used both for training and as JumpTest

#### Scenario: Exercise count

- **WHEN** the runtime reads `exerciseLibrary.count`
- **THEN** the value is `30`

#### Scenario: Exercise IDs are unique kebab-case

- **WHEN** the runtime constructs a `Set` of `exerciseLibrary.map(\.id)`
- **THEN** the set has 30 elements
- **AND** every id matches `^[a-z][a-z0-9-]*$`

### Requirement: Exercise 元数据字段

Each `Exercise` struct SHALL have these fields:

- `id: String` (kebab-case)
- `nameZH: String` (中文名)
- `nameEN: String` (English name)
- `category: ExerciseCategory` enum (`.barbell / .dumbbell / .bodyweight / .machine / .jump`)
- `defaultVelocityVariant: VelocityVariant` (`.mv / .mpv / .pv`)
- `referenceV1RM: Double?` (m/s, the speed at 1RM, from literature)
- `defaultVLCeiling: Double` (default VL%, e.g. 20 for `.strength` goal)
- `defaultTargetVelocityRange: ClosedRange<Double>` (m/s, default target band for the user's chosen training goal)
- `isUnilateral: Bool` (true for Bulgarian split squats etc.)
- `sfSymbol: String` (an SF Symbol name for the icon)
- `citations: [PaperCitation]` (the literature backing the V1RM / VL defaults)
- `notes: String?` (any caveats — e.g. "MPV preferred due to sticking-point braking")

#### Scenario: Bench press has MPV variant

- **WHEN** the runtime looks up `exerciseLibrary.first(where: { $0.id == "bench-press" })`
- **THEN** `defaultVelocityVariant == .mpv`
- **AND** `referenceV1RM` is approximately `0.17`
- **AND** at least one citation references González-Badillo & Sánchez-Medina (2010)

#### Scenario: CMJ uses peak velocity

- **WHEN** the runtime looks up the `cmj` exercise
- **THEN** `defaultVelocityVariant == .pv`
- **AND** `category == .jump`

### Requirement: 默认速度区间随训练目标变化

The system SHALL provide a function `defaultVelocityRange(for exercise: Exercise, goal: TrainingGoal) -> ClosedRange<Double>` that returns the recommended velocity band based on the user's training goal.

Default ranges by goal (matching VL thresholds in PRD §8.4):
- `.power` (爆发) → narrow upper-band (low load, high velocity)
- `.strength` (力量) → mid band (heavy load, moderate velocity)
- `.muscle` (增肌) → wider mid-low band
- `.fatLoss / .general` → broad band

#### Scenario: Strength goal returns mid band for squat

- **WHEN** `defaultVelocityRange(for: backSquat, goal: .strength)` is called
- **THEN** the range is approximately `0.45...0.65` m/s (per literature for ~80-90% 1RM)

### Requirement: 论文引用关联

Each Exercise's velocity defaults MUST cite at least one paper from `Shared/Citations/Citations.swift`. The citations MUST include at minimum:

- González-Badillo & Sánchez-Medina (2010) for V1RM values
- Sánchez-Medina & González-Badillo (2011) for VL thresholds
- Sánchez-Medina et al. (2010) for MPV variant rationale

#### Scenario: Every exercise cites at least one paper

- **WHEN** `exerciseLibrary.allSatisfy { !$0.citations.isEmpty }` is evaluated
- **THEN** the result is `true`

### Requirement: SF Symbol 图标命名

Each exercise SHALL specify a valid SF Symbol name in `sfSymbol`. The name MUST exist in SF Symbols 4 (Apple's bundled set, available on iOS 16 / watchOS 9).

Recommended mapping examples:
- Squats → `figure.strengthtraining.traditional`
- Bench / Press → `figure.strengthtraining.traditional`
- Deadlifts → `figure.strengthtraining.traditional`
- Pull-up / Dip → `figure.pull.up` (where applicable) or `figure.strengthtraining.traditional`
- CMJ → `figure.jumprope` or `figure.run`

#### Scenario: Every symbol resolves

- **WHEN** the runtime constructs `Image(systemName: exercise.sfSymbol)` for every exercise
- **THEN** the image is non-nil
