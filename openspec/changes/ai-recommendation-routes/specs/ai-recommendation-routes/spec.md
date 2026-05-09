## ADDED Requirements

### Requirement: PR retest template builder

`RecommendationTemplateBuilder.buildPRRetest(exerciseId:, lastTopWeight:, in:)` SHALL create:

- a Template named `"PR 重测 · <exerciseName>"`
- one TemplateItem at index 1 with the given exerciseId, vlCeiling=30, restSeconds=180
- 7 TemplateSetSpec rows:
  - 2 warm-up: 40% × 8 @ rest 90s, 65% × 5 @ rest 120s
  - 5 work: 80%×5/150s, 90%×3/180s, 95%×2/180s, 100%×1/180s, 105%×1/0s

#### Scenario: Build for 100kg top weight

- **WHEN** `buildPRRetest(exerciseId: "back-squat", lastTopWeight: 100, in: ctx)` runs
- **THEN** the template has 7 setSpecs at weights [40, 65, 80, 90, 95, 100, 105] kg

### Requirement: Deload template builder

`RecommendationTemplateBuilder.buildDeload(baseTemplate:, in:)` SHALL clone all items + setSpecs from base, multiplying every weight by 0.85 and decrementing every WORK set's reps by 1 (clamped ≥ 1). Warm-up sets keep their reps. The new Template's name is `"减载 · <baseName>"`.

#### Scenario: Deload a 5×5@100kg work item

- **WHEN** baseTemplate has one item with 5 work sets at 100kg×5
- **THEN** the deload Template has 5 work sets at 85kg×4

### Requirement: AIRecommendation carries hint payload

`AIRecommendation` SHALL include optional `exerciseIdHint: String?` and `weightHint: Double?` fields. The engine populates them for `prRetest` (top exercise + max weight) and `templateIdHint` for `deload` (latest template).

### Requirement: AI cards are tappable

In `TodayView`, every AI recommendation card SHALL be wrapped in a `Button` whose action invokes `applyRecommendation(rec)`. The card's visual style is unchanged.

#### Scenario: Tap a PR retest card

- **WHEN** the user taps the "深蹲 · PR 重测" card
- **THEN** `RecommendationTemplateBuilder.buildPRRetest` is called with the hint values
- **AND** the resulting Template is pushed via navigationDestination → PlanView

### Requirement: Recommendation routing rules

`applyRecommendation(rec)` SHALL:

- `.deload` + valid templateIdHint → buildDeload + push PlanView
- `.deload` + missing baseTemplate → call createNewTemplate fallback
- `.prRetest` + valid hints → buildPRRetest + push PlanView
- `.prRetest` + missing hints → call createNewTemplate fallback
- `.cmjTest` → present alert "在 Apple Watch 上启动 CMJ"

#### Scenario: cmjTest does not navigate

- **WHEN** the user taps a CMJ recommendation card
- **THEN** an alert appears advising them to use the Watch app
- **AND** no navigation occurs
