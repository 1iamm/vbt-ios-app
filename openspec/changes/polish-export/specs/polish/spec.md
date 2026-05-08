## ADDED Requirements

### Requirement: 一致的 EmptyStateCard

The system SHALL use `EmptyStateCard(title:subtitle:)` consistently across TodayView / HistoryView / PRListView / ExerciseTrendView for "无数据" presentations.

### Requirement: README 更新

The project README SHALL list all 10 OpenSpec changes with their status (all expected to be marked complete after polish-export).

### Requirement: 全量编译

After polish-export is complete:
- `xcodebuild` against `VBTrainer` target on iphoneos SDK → BUILD SUCCEEDED
- `xcodebuild` against `VBTrainerWatch Watch App` target on watchos SDK → BUILD SUCCEEDED
- All test files compile (real test execution requires simulator runtime download, deferred to user verification).
