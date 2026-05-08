## ADDED Requirements

### Requirement: 首次启动引导

`OnboardingView` SHALL appear only when no `UserProfile` exists in the database. After the user completes onboarding (saving a `UserProfile`), `RootView` is shown for the rest of the session.

### Requirement: 5 步引导

The onboarding consists of 5 steps in order:
1. Welcome (1-line value prop, 1 SF Symbol)
2. HealthKit 权限申请
3. 基础信息 (年龄 / 性别 / 身高 / 体重)
4. 训练背景 (训练年限 / 训练目标 / 体型)
5. 完成 (创建 UserProfile，进入主界面)

#### Scenario: Onboarding finishes saves profile

- **WHEN** the user completes step 5
- **THEN** a `UserProfile` is inserted into the database
- **AND** the app navigates to `RootView`
