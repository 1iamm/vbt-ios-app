# Tasks: 修复 5s inactivity 自动结组 bug

- [x] 改 `LiveWorkoutController.swift` inactivity timer 5s → 12s
- [x] 加 8s 预警 `HapticFeedback.inactivityWarning()`
- [x] 新增 `HapticFeedback.inactivityWarning()` static method（`.notification`）
- [x] 更新原 5-second 注释 → 12-second
- [ ] CI 通过（iOS + watchOS 编译 + 算法测试 + UI test）
- [ ] Round 2 audit 时验证：finding IX-F3 状态 = done
