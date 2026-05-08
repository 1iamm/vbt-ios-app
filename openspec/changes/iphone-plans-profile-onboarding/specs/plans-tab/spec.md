## ADDED Requirements

### Requirement: 模板列表

`PlansView` SHALL display all `Template` records sorted by updatedAt desc, with a "新建模板" button at the top right.

### Requirement: 模板编辑

`TemplateEditorView` SHALL allow creating or editing a template with: name, optional notes, ordered list of TemplateItems (each = exercise + sets + reps + targetWeight + targetVelocityRange + vlCeiling + restSeconds + side).

#### Scenario: New template can save

- **WHEN** user creates a template with at least one TemplateItem and taps Save
- **THEN** it appears in the list

### Requirement: 日历挂载（基础）

`CalendarPlanView` SHALL show a month grid; tapping a day reveals which template (if any) is scheduled. Persistence of the day→template mapping is provided via simple `@AppStorage` JSON (full plan execution is Proposal 9's scope).
