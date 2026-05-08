## ADDED Requirements

### Requirement: 集中式导航路径

The system SHALL provide `WatchNavigation` (an ObservableObject) with a `path: NavigationPath` and route enum `WatchRoute` enumerating: `readiness / cmjCountdown / cmjGo / cmjResult / exercisePicker / weightInput(exerciseId) / liveWorkout(setup) / rest(snapshot) / summary(snapshot) / planProgress / planNext / prCelebration / vlStop / rpeInput`.

#### Scenario: Push and pop

- **WHEN** the navigation pushes `.exercisePicker` then `.weightInput("back-squat")`
- **THEN** popping returns to ExercisePicker

### Requirement: Root 引用 navigation

`WatchRootView` SHALL host the `NavigationStack` and inject the `WatchNavigation` into the environment so child views can navigate.
