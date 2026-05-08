## ADDED Requirements

### Requirement: Profile Tab

`ProfileView` SHALL render a `Form` with sections:
- 个人资料 (link to `ProfileEditorView`)
- 训练设置 (link to `SettingsView`)
- 数据 (导入 / 导出 placeholder, finalized in Proposal 10)
- 隐私 (本地存储说明文本)
- 关于 (版本 / 论文引用 link / 致谢)

### Requirement: 画像编辑

`ProfileEditorView` SHALL bind to the singleton `UserProfile` and let the user edit age / sex / height / weight / bodyType / trainingExperience / trainingGoal / measuredHRMax / restingHR.

### Requirement: 设置

`SettingsView` SHALL allow editing weightUnit / crownStep / defaultRestSeconds / vibrationEnabled / cmjOnEachWorkout.
