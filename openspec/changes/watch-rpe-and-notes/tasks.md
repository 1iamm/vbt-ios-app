## 1. Watch
- [x] 1.1 `WatchSummaryView` 加 RPE 数字 + 表冠 + 色阶 + 标签
- [x] 1.2 `WatchSummaryView` 加 3 选 1 感受 tag
- [x] 1.3 LiveWorkoutController 加 `completeWithFeedback(rpe:notes:)`
- [x] 1.4 "完成" 按钮调 completeWithFeedback

## 2. iPhone
- [x] 2.1 `WorkoutDetailView` feedbackCard（已填 / 未填两态）
- [x] 2.2 RPE 圆环徽章 + 色阶
- [x] 2.3 `FeedbackEditorSheet`（Slider + TextField + 6 预设 tag chip + dedup append）

## 3. 编译/真机
- [ ] 3.1 用户 macOS 本机 `xcodebuild` 通过
- [ ] 3.2 真机：训完 → Watch summary 转表冠选 RPE → 完成 → iPhone 详情页看到 RPE 圆环 + "感受：正常" 笔记 → 点编辑改成 RPE 9 + 加 "腰累" tag
