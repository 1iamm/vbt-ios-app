# Tasks: V1 项目代码结构重构

## 前置条件（未满足前不启动 Round 1）

- [ ] Task 2 (`multi-agent-ux-iteration`) Round 1 修复批次 B1+B2+B4 全部 done 或 wontfix-rationale
- [ ] Task 2 Round 2 复审已经至少跑过一轮
- [ ] 当前 main 上 CI 全绿（无 flaky 残留）

## Round 1 · Audit

- [ ] 写 prompt for **架构师 agent**：模块边界 / 依赖方向 / 抽象层次
- [ ] 写 prompt for **性能 agent**：算法热点 / SwiftUI 重渲染 / SwiftData 查询
- [ ] 写 prompt for **测试 agent**：覆盖盲区 / 难测代码 / 假数据复用
- [ ] 平行跑 3 agent
- [ ] 汇总 finding，写进本 `tasks.md` 的 Round 1 Findings 表

## Round 1 Findings 表

（待 Round 1 audit 完成后填充）

## Round 2 · 重构设计

- [ ] 写 design.md：文件移动 / rename / 拆分 / 合并清单
- [ ] 标记**确定可删除**的孤儿代码（grep 全文 0 引用的 view / extension / type）
- [ ] 写 ADR 用一句话解释每个重大决定
- [ ] 设计 PR 切分策略（一个 PR 一类改动，diff < 800 行）

## Round 3 · 执行

- [ ] 按设计批量改（多个 PR）
- [ ] 每个 PR 跑完整 CI（含 UI test）确认 0 用户可见行为变化
- [ ] 删孤儿代码（用户明确说"不用保留老版本代码"）
- [ ] 移动 OpenSpec changes：completed 进 `openspec/specs/`、deprecated 删除
- [ ] 重写 CLAUDE.md "项目大脑" 反映新结构
- [ ] 归档本 change 自己进 `openspec/specs/`

## 退出门槛

- [ ] 3 agent 复审一致 PASS（无 P0/P1 残留）
- [ ] 仓库 LOC 净减或持平
- [ ] grep 全文：0 个孤儿代码
- [ ] `openspec/changes/` 目录里只剩进行中的 V1.5+ changes
- [ ] CLAUDE.md 反映新结构，新会话 5 分钟内能上手
