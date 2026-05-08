## ADDED Requirements

### Requirement: 综合时间轴图表

`ComprehensiveChartView` SHALL render a single Swift Charts `Chart` containing all of the following layers, time-aligned on the x-axis:
- A LineMark series for heart-rate over time, colored `Tokens.Color.Data.heartRate`
- A series of PointMark per rep, y = velocity (in m/s), colored `Tokens.Color.Data.velocity`, with separate symbol shape per set
- RuleMark vertical separator at each set boundary, with a label showing weight at top
- RectangleMark with `.fill(.gray.opacity(0.10))` for inter-set rest periods
- A horizontal RuleMark dashed line at the configured VL ceiling (if any), labeled "VL ceiling"

The chart SHALL have two Y axes (left = bpm, right = m/s) with appropriate domain scaling.

#### Scenario: Renders without crashing on empty data

- **WHEN** the workout has no reps and no heart-rate samples
- **THEN** the chart renders an empty state placeholder text rather than crashing

#### Scenario: Set boundaries align

- **WHEN** the workout has 3 sets at times T1 < T2 < T3
- **THEN** there are 3 vertical RuleMarks at those timestamps
