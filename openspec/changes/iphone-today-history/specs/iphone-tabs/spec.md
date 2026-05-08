## ADDED Requirements

### Requirement: 4 Tab Bar 主结构

The system SHALL replace the placeholder `RootView` with a `TabView` containing 4 tabs in this order with these icons:
- 今天 (`today` icon, SF Symbol `circle.lefthalf.filled`)
- 训练 (`train` icon, SF Symbol `dumbbell.fill`)
- 历史 (`history` icon, SF Symbol `clock`)
- 我的 (`profile` icon, SF Symbol `person.crop.circle`)

#### Scenario: Tab switching

- **WHEN** the user taps each tab in turn
- **THEN** the corresponding view is displayed
- **AND** the selected tab indicator reflects the active tab

### Requirement: Tab 占位

Plans (训练) and Profile (我的) tabs SHALL display placeholder content until Proposal 6 implements them.
