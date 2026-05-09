## ADDED Requirements

### Requirement: Top exercise/set band

The chart SHALL render a horizontal band above the plot area with one independent colored chip per WorkoutSet. Same-exercise sets share the same color from a fixed palette of up to 8 hues. Adjacent same-exercise sets DO NOT merge — gaps between sets are visible.

#### Scenario: 3 sets of squats followed by 2 sets of bench

- **WHEN** the workout has [Set1 squat, Set2 squat, Set3 squat, Set4 bench, Set5 bench]
- **THEN** sets 1-3 are blue chips (squat color), sets 4-5 are orange chips (bench color)
- **AND** the band shows 5 distinct chips with gaps between

#### Scenario: First chip of a new exercise has small-caps label

- **WHEN** Set4 is the first bench-press set after squat sets
- **THEN** above Set4's chip a label like `BENCH` appears in small-caps tracked text

### Requirement: Heart-rate line

When `showHR == true`, the chart SHALL draw a HeartRate LineMark using `Tokens.Color.Data.heartRate` connecting all `HeartRateSample`s in `workout.heartRateSamplesData`.

#### Scenario: Toggle off

- **WHEN** the user taps the 心率 legend chip and `showHR` flips to false
- **THEN** the line disappears within one frame

### Requirement: Velocity scatter

When `showVelocity == true`, every Rep in every set SHALL render as a circle PointMark at its `timestamp` and `meanVelocity` (mapped to BPM Y-domain via `velocityToBpm`).

### Requirement: VL% dashed segment per set

When `showVL == true`, for every set SHALL draw a dashed horizontal line spanning [firstRep.timestamp, lastRep.timestamp] at a Y value computed from the set's velocity-loss percent.

#### Scenario: Set with VL = 18%

- **WHEN** firstRep MV = 0.62 and lastRep MV = 0.51 (vl ≈ 17.7%)
- **THEN** a dashed segment is drawn between those two timestamps at the y position corresponding to VL ≈ 18

#### Scenario: VL segments do not connect across sets

- **WHEN** there are 3 sets with VL = 5%, 12%, 22%
- **THEN** 3 separate dashed segments appear; no line joins them across the gap

### Requirement: Dual-row X-axis

The chart SHALL render time labels in two rows below the plot area:

- Top row: absolute time `HH:mm` in primary label color
- Bottom row: relative time `+Nm` (minutes since workout start) in tertiary label color

The two rows align to the same 5 evenly-spaced tick positions.

#### Scenario: 60 min workout starting at 19:24

- **WHEN** start = 19:24, total = 60 min
- **THEN** ticks at frac 0/0.25/0.5/0.75/1 read [19:24, 19:39, 19:54, 20:09, 20:24] over [+0m, +15m, +30m, +45m, +60m]

### Requirement: Tappable legend toggles series

The legend SHALL have one tappable chip per series (心率 / 速度 / VL%). Tapping flips that series' visibility flag with an animated transition. The corresponding axis label group dims when its series is hidden.

#### Scenario: Tapping 速度 hides scatter

- **WHEN** the user taps 速度 with `showVelocity = true`
- **THEN** all PointMarks disappear
- **AND** the right-side axis labels (m/s scale) dim to tertiary label color
