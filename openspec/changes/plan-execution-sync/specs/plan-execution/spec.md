## ADDED Requirements

### Requirement: Watch 端今日计划展示

`WatchHomeView` SHALL display a "今日计划" card if a TemplateSnapshot for today's date is in storage. The card shows template name + first item preview + "查看计划" button that pushes `WatchPlanProgressView`.

### Requirement: PlanProgressView 真实数据

`WatchPlanProgressView` SHALL render the items from the stored TemplateSnapshot (not mock data). Each item shows: order, exercise, target weight/reps; current item is highlighted.

### Requirement: PlanNextView 真实数据

`WatchPlanNextView` SHALL show the next pending item with all targets, and the "开始本动作" button SHALL navigate to `WeightInput` pre-filled with the target weight.
