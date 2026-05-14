# Tasks: 多 Agent UX 迭代 · Round 1 Findings + 处理状态

> Round 1 audit 由 4 个 subagent 平行跑（2026-05-13），共 61 条 finding。本 tasks.md 是**持久化**——下次会话开启后查这里看下一步。

## Round 1 状态总览

- Round 1 audit：✅ 完成（4 agent 报告全部归档于本目录）
- Round 1 修复：🟡 进行中（2026-05-14 第一批自决项已 dispatch — IX-F7, UI-§3-P2, PM-F12, UI-§3-P1）
- Round 2 复审：未开始
- Round 3 复审：未开始

## 2026-05-14 进度日志

- [x] **IX-F7** [P1] — 跳过 rest 双击防抖（PR #86）
- [x] **UI-§3-P2** — `Tokens.Color.ai` 提取，消除 2 处硬编码（PR #87）
- [x] **PM-F12** — HeartRateZonesDonut 孤儿组件（PR #77 已删）
- [x] **UI-§3-P1** — HRZone SwiftUI 内建色 → 因 PR #77 删了组件本身，自动消解
- [x] **PM-F16** — Profile 隐私文案 — 检查后发现现有文案已与 CLAUDE.md 2026-05-08 hybrid 模型一致（描述了 V1 本地 + V1.5+ 云同步）
- [x] **IX-F15** — Watch/iPhone 速度精度一致性测试（PR #76）
- [x] **IX-F3** — 5s → 12s + 8s 预警（PR #55）
- [x] **IX-F4** — Watch→iPhone ACK + outbox（已 mitigated by transferUserInfo fallback）

## 高优先级 finding（多 agent 印证 / 单 agent 高严重度）

按修复批次组织。每条 finding 编号 `<agent>-F<N>`：PM/UI/IX/USR 分别代表 产品/UI/交互/用户。

### B1 · 数据正确性 / 完整性硬伤（自决，不打扰用户）

- [x] **IX-F3** [P0] LiveWorkoutController 5s 自动结组 → 12s + 8s 震动预警 — **done in PR #55** (`ux-fix-inactivity-timeout-r1`, merged `bbfb41c`)
  - File: `LiveWorkoutController.swift:597-614`
  - 后果：重深蹲架杠 5-7s 会被算成下一组
- [x] **IX-F4** [P0] WorkoutDone Watch→iPhone 同步加 ACK + 本地 outbox — **数据完整性部分已 mitigated by existing transferUserInfo fallback**
  - File: `WatchScreens.swift:1466-1476`, `WatchConnectivityService.swift:83-95`
  - 现状：`send(message:)` 已经走 `sendMessage` → 失败时 fallback 到 `transferUserInfo`（Apple 内置队列，survives app lifecycle，自动 retry）
  - **数据丢失风险已消除**（弱信号场景由 OS 队列兜底）
  - **剩余 UI 层 finding**（"await delivery confirmation" 按钮 loading 态）→ 拆分到 UI 批次，需用户决策视觉
- [x] **IX-F7** [P1] iPhone「跳过」双击防抖（PR #86 2026-05-14）— Watch 端 `advanced` flag 已有，iPhone 端 dedup 已补齐
  - File: `LiveWorkoutView.swift:380-396`, `WatchScreens.swift:418-424`

### B2 · 关键 UX（用户决策已收齐 2026-05-14；5 个实现 PR 已 dispatch）

- [x] **USR-F4 / IX-F8 / USR-F14** [P0 三 agent 印证] 「在 Watch / iPhone 上练」每次都问 → **只在 Watch 不可达时弹** (PR #91)
- [x] **IX-F1 / IX-F2 / USR-F8** [P0 多 agent 印证] 「结束本组」按钮 → **保持单击但放大 + accent 色** (PR #92, 30→44pt + accent 色)
- [x] **IX-F11 / USR-F6** [P0 双 agent 印证] SetResult 屏 → **保留独立屏 + 3s 自动 advance + 点击跳过** (PR #93)
- [x] **PM-F7 / USR-F5** [P0 双 agent 印证] "AI 推荐" Section → **改名"训练建议"** (PR #90)
- [x] **USR-F12** [P0] PR 庆祝路径接线 → **Watch 同步成功后 iPhone Today 弹**（NotificationCenter 兜底 ad-hoc workout，PR #94）

### B3 · 视觉一致性（视觉 token / 颜色 / 字号）

- [ ] **UI-§3-P0** [P0] `Color.orange` 写死 8 处 → 跟随 `accent`（GoalTheme）— **需用户决策**：写死 orange（按 V4 设计稿）还是改为 accent（GoalTheme 变色）。本身是 token 替换，但视觉默认会变（如果用户改训练目标到耐力 → 黄变蓝）
  - Files: `LiveWorkoutView.swift:200-201,235,258,415,436,489`、`TodayView.swift:235,258`
- [ ] **UI-§1-P0** [P0] `Tokens.Font` 扩档 + 全局替换 401 处 `.font(.system(size:))` 
  - 大改动，可能要分多个 PR 按文件目录批量推
- [ ] **UI-§2-P0 / UI-§6-P0 / IX-F5** [P0] Watch 字号 7-9pt 27 处 → caption2(13)+；±10s 按钮 28×28 → 44×44
  - File: `WatchScreens.swift:201,236,251,393,407,454,471,474,487,492`

### B4 · 功能补全 / 架构

- [ ] **PM-F1** [P0] Watch 端 CMJ 测试 View（算法 + 模型 + Store 全在，缺 Watch UI 入口）
  - Files: `WatchRootView.swift` 路由 / 新 `WatchCMJTestView.swift`
- [ ] **PM-F2** [P0] Workout 多动作模型（schema migration）
  - Files: `Workout.swift:17`、`WorkoutDetailView.swift:282`
  - 用户决策：加 `parentSessionId: UUID?` 串起多个 Workout vs 让 WorkoutSet 直接持 `exerciseId`
  - **V1.5 云同步前最后窗口**

### P1 · 次优先级（一句话概述，详情见 audit 报告原文）

- [ ] PM-F3：Onboarding 缺 measuredHRMax / restingHR 采集
- [ ] PM-F4：WorkoutDetail 不展示 VL% / Peak Velocity
- [ ] PM-F5：长期趋势"训练频率热力图"完全没做
- [ ] PM-F8：Watch 多动作训练总结丢 RPE
- [ ] PM-F9：CelebrationCard 加"查看复盘 →"主按钮
- [ ] PM-F10：Readiness 卡片点击无反应（chevron 是装饰）
- [ ] PM-F11：主导航没"趋势" tab；ExerciseTrendView 入口深
- [ ] PM-F14：Readiness 5 维度数据采到但 UI 不全
- [ ] UI-§2-P1：iOS LiveWorkout 大数字 56/96/40/88 横跳无规律
- [ ] UI-§2-P1：RedesignComponents 内部 SectionHeader 13pt vs TodayHeader 30pt 阶梯异常
- [x] UI-§3-P1：HRZone 颜色 — 因 PR #77 删除 HeartRateZonesDonut 组件本身，自动消解
- [ ] UI-§4-P1：4pt grid 系统性破坏（spacing 10/14/18 等非 token 值散落）
- [ ] UI-§5-P1：7 处手搓 RoundedRectangle 卡片 → 抽 `CardContainer` modifier
- [ ] UI-§5-P1：primary CTA 按钮重复实现 3 次 → 抽 `PrimaryCTAButtonStyle(accent:)`
- [ ] IX-F5 [P1] Watch LiveWorkout 顶部 9pt 文字 + 缺大字号 set index
- [ ] IX-F6 [P1] iPhone LiveWorkoutView "结束训练" 二级按钮位置鬼祟
- [ ] IX-F9 [P1] Watch 新用户进 Today 后开始第一次训练需 5+ 次点击
- [ ] IX-F10 [P1] AI 推荐 deload 卡片缺"我就要这个，直接开始"按钮
- [ ] IX-F12 [P1] SetReady 4 个 cell focus + crown 手感不一致
- [ ] USR-F1 [P0/争议] "体型 5 选 1" 训练背景字段无意义 → 删 or 改成"深蹲 1RM"
- [ ] USR-F2 [P1] 身高字段 V1 算法用不到 → 删
- [ ] USR-F3 [P1] Onboarding 强制选 trainingGoal → 默认"力量"+ 入口
- [ ] USR-F10 [P1] 综合时间轴漂亮但无结论文案
- [ ] USR-F11 [P2] Watch summary RPE + Feeling 双填 → 删 Feeling
- [ ] USR-F13 [P1] e1RM 藏在第 4 层级 → WorkoutDetail Hero + Watch summary 露出
- [ ] USR-F15 [P1] Today readiness 圆环占 1/3 屏但无 action call
- [ ] USR-F16 [P0 功能建议] 「上次同组对比」横向叠加（VBT 核心价值）

### P2 · 低优先级

- [ ] PM-F6：M9 本地备份只有导出没恢复
- [x] PM-F12：HRZonesDonut 是孤儿组件 — PR #77 已删 (2026-05-14)
- [ ] PM-F13：5 种 PR 平级列在深处
- [ ] PM-F15：HealthKit 部分数据采了但 UI 完全不读（血氧 / VO2Max / 步数）
- [x] PM-F16：Profile 文案 — 检查后发现已与 hybrid 模型对齐（描述 V1 本地 + V1.5+ 可选云同步，HealthKit 永不上云）
- [ ] PM-F17：训练模式术语 SettingsView vs TodayView 不一致
- [ ] UI-§3-P2：`aiHue` private 在组件内 + TodayView 又复制一份 → 提为 `Tokens.Color.ai`
- [ ] UI-§4-P2：Section header 上下间距各处不一 → 抽 `.sectionPadding()`
- [ ] UI-§5-P2：StatsView deltaTile vs ScheduledTrainingCard.stat() 重复
- [ ] UI-§6-P1：Watch chip 用 `.blue` 实色不友好 OLED
- [ ] IX-F13 [P2] iPhone RestView 88pt 倒计时在 SE 屏裁切
- [ ] IX-F14 [P2] WorkoutDetail 综合时间轴横屏过渡突兀
- [x] IX-F15 [P2] Watch/iPhone 速度精度一致性测试 — PR #76 (2 tests) merged 2026-05-14
- [ ] USR-F9 [P2] Watch 休息倒计时 ±10s 按钮触控目标太小（与 UI-§6 重叠）

## Round 2 触发条件

- B1 + B2 + B3 + B4 中至少 80% 标记 done 或 wontfix
- 截图 e2e 跑通：onboarding → today → start → live → rest → summary → history
- 准备好 audit 重启 prompt（复用 `design.md` 中的 3 角色定义）

## Round 1 → Round 2 → Round 3 闭环

每 round 完成 → 跑 3 agent 复审 → 写新 round 报告 → 更新本 `tasks.md` 状态。
所有 P0/P1 都 done/wontfix-rationale 且两轮复审都 PASS → Task 2 完成。
