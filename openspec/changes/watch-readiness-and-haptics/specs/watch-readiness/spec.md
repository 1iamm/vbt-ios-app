# watch-readiness

## Purpose

watchOS「今日准备度」屏的布局契约：在 40mm/41mm 表盘也能让所有交互操作在首屏内
可见，且支持 Dynamic Type 大字号优雅滚动兜底。

## Requirements

### Layout

- 屏幕 SHALL 以 `WatchScreenChrome(title: "今日准备度")` 包裹，外层为 `ScrollView`
- Readiness 圆环 SHALL 固定 110×110pt 外径
- 圆环内中心分数 SHALL 为 28pt SF Rounded Bold
- 圆环上方顶部 Spacer SHALL ≤ 12pt
- 三列 miniStat（HRV / RHR / 睡眠）SHALL 单行展示，间距 ≤ 6pt，数字 12pt
- 「跳过」操作 SHALL 为圆环下方 13pt 灰色文本链接，role `.cancel`
- 「CMJ 测试」操作 SHALL 为底部全宽 borderedProminent 胶囊，accent 配色
- 整体内容自然高度在 40mm 表盘（197pt）上 SHALL ≤ 197pt（首屏不滚），在 49mm
  表盘（242pt）上首屏占满不留过多空白

### Behaviour

#### Scenario: 用户在 40mm 表盘进入 Readiness 屏
- **WHEN** 屏幕首次渲染
- **THEN** 圆环、3 列 stat、跳过链接、CMJ 主按钮全部首屏可见无截断

#### Scenario: 用户启用 Dynamic Type XXL
- **WHEN** 系统字号设为 accessibilityLarge 及以上
- **THEN** 内容垂直撑高超出屏幕，ScrollView 自动启用滚动；CMJ 主按钮通过滚动可达

#### Scenario: 用户点「跳过」
- **WHEN** 点击「跳过」文本链接
- **THEN** 路由跳转到 `.exercisePicker`（不进 CMJ 流程）

#### Scenario: 用户点「CMJ 测试」
- **WHEN** 点击底部胶囊主按钮
- **THEN** 路由跳转到 `.cmjCountdown`
