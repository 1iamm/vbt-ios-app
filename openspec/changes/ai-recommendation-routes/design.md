## Context

V1 哲学不接真 AI 模型，但用户希望 "推荐卡看起来有 AI" 且 "点了能落地"。所以 rule-based 推荐 + 模板 builder + 自动跳 PlanView 三件事拼起来形成可用闭环。

## Decisions

### D1：PR 重测 = 5 组金字塔 + 2 热身

50% × 8 (warm) → 65% × 5 (warm) → 80% × 5 → 90% × 3 → 95% × 2 → 100% × 1 → 105% × 1。最后一组 105% 是 attempt — 重量取 lastTopWeight × 1.05 以激励出 PR。
休息逐组拉长（90 → 120 → 150 → 180 → 180 → 180 → 0）。

### D2：减载 = base × 0.85 + reps -1，仅 work sets

base template 是用户最近 updated 的 Template。deload 复制它的 items + setSpecs：
- weight × 0.85（保留原 reps 但 -1，不低于 1）
- 热身组只 weight 缩水，reps 不动
- rest 不变（神经恢复优先）
- name 前缀 "减载 · "

减载的核心目的是降量保速度，而不是新结构 — 所以克隆比从零生成更稳定。

### D3：CMJ 测试不接 push，只 alert

CMJ 流程已经存在于 Watch（cmjCountdown → cmjGo → cmjResult）。要 iPhone push 触发就得扩 ConnectivityMessage 协议 + Watch nav handler。本 change 不做（范围控制），改用 alert 让用户主动启动。下次 change 可加 `.cmjLaunch` message。

### D4：找不到底 template / weight 时降级到新建

deload 没有 baseTemplate / prRetest 没有 lastTopWeight → 直接 fallback 到 createNewTemplate()。理由：避免 UI 卡死或弹空内容。

### D5：生成的模板进入 "我的模板" 列表（持久化）

用户决定要删除可以在 PlanView 顶部 menu 删。优点：自动出现在历史里方便后续 reuse；缺点：列表可能膨胀。V1.5 加 "AI 推荐生成" 标签 + 自动 60 天后清理。

## Risks / Trade-offs

- **Risk**: PR 重测 105% × 1 attempt 失败可能让用户灰心。**Trade-off**：rest 180s 给充分恢复；attempt 失败用户也能学到状态信息
- **Trade-off**: deload 的 -1 rep + -15% weight 可能对增肌目标不够激进；power 目标足够。下次按 goal 微调系数
- **Trade-off**: cmjTest 不发 push 让 Watch 自动跳到 cmj — V2 加，需要 Watch 端 handler

## Open Questions

无。
