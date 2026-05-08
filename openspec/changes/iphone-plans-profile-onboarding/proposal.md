# Proposal: iPhone Plans + Profile + Onboarding

## Why

Proposal 5 完成了 4-Tab 主结构和 Today/History。本 proposal 实现：
- Plans Tab（用户自建模板列表 + 编辑器 + 日历挂载）
- Profile Tab（用户画像编辑 + 全部设置 + 论文引用页）
- 首次启动 Onboarding 流程（画像采集 + HealthKit 权限请求）

## What Changes

- `Views/Train/PlansView.swift`：模板列表 + "新建" 按钮
- `Views/Train/TemplateEditorView.swift`：模板创建 / 编辑
- `Views/Train/CalendarPlanView.swift`：日历视图，把模板挂到某天
- `Views/Profile/ProfileView.swift`：画像 + 设置 + 数据 + 隐私 + 关于
- `Views/Profile/ProfileEditorView.swift`：年龄/性别/身高体重/训练年限/目标
- `Views/Profile/SettingsView.swift`：单位/Crown 步进/休息时长/每动作目标速度
- `Views/Profile/CitationsListView.swift`：18 篇论文列表 + 点击跳 URL
- `Views/Onboarding/OnboardingView.swift`：首次启动 5 步流程
- `Views/Onboarding/HealthKitPermissionView.swift`：HealthKit 权限申请

## Capabilities

### New Capabilities

- `plans-tab`: 模板 CRUD + 日历挂载
- `profile-tab`: 画像编辑 + 设置
- `onboarding`: 首次启动引导
- `citations-display`: 论文清单视图

## Impact

- 仅 iOS target
- 计划真正下发到 Watch 留给 Proposal 9
- HealthKit 真正读数据留给 Proposal 7
