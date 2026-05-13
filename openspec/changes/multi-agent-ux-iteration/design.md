# Design: 多 Agent UX 迭代框架

## Audit 委员会角色

每轮 audit 用 **3-4 个独立 subagent 平行跑**（不互相看输出），各回一份 markdown：

| Round 1 角色 | 视角 | 必读路径 |
|---|---|---|
| **产品经理** | PRD 落地 gap / 场景断点 / 缺失能力 / 数据可见性 / 命名一致性 | `PRD.md` / `openspec/changes/**` / `Shared/Models/` |
| **UI 设计师** | Token 一致性 / 字号层级 / 颜色滥用 / 间距 / 组件复用 / Watch HIG | `Shared/Theme/Tokens.swift` / `VBTrainer/Views/**/*.swift` |
| **交互设计师** | 训练中 Watch 摩擦 / 跨设备一致 / 错误恢复 / 第一次使用 / 导航回退 / 动画 | `VBTrainer/Views/Today` / `Plan` / `History` / Watch screens |
| **用户视角（Zexi）** | 真实力量训练者吐槽视角；强调"我不会用这个"的 P0 痛点 | iOS + Watch 所有用户可触达界面 |

| Round 2+ 角色（复审）| 视角 |
|---|---|
| **可靠性** | 数据完整性 / 边界场景 / 失败恢复 / 跨设备同步 |
| **稳定性** | 状态机正确性 / 并发竞态 / 内存 / 性能 |
| **美观** | 视觉一致 / Token 纪律 / 跨平台体验对齐 / 排版细节 |

## 每条 finding 的标准格式

```
### F<N> [P0/P1/P2] 简短标题
- **File**：`path/to/file.swift:line-range`
- **现状**：...
- **后果**：...
- **建议**：...
```

存档在 `tasks.md` 表格里，每条对应一个 PR（或一组合并 PR）。

## 处理状态机

```
pending → in-progress → done
              ↓
          wontfix-with-rationale
              ↓
          deferred-to-V2 (写明 PRD 哪一段对应)
```

## 退出门槛

每个 Round 完成后跑 3-agent 复审。每个 agent 给一个判决：
- **PASS**：本 round 0 P0 + 0 P1
- **FAIL**：列剩余 P0/P1，进下一 round

**Task 2 完成** ≡ 连续两个 Round 3-agent 都 PASS。

## 与 Task 1 工具链协作

- Round 修完一批 PR 后，**让 CI 自动跑截图 e2e**
- 截图被 release + 评论嵌入
- **复审 agent 必读 PR 截图**（不仅看 diff）
- 这保证视觉级的回归被 agent 捕获

## OpenSpec 中的子 change

Round 2+ 每批 PR 都对应一个独立 OpenSpec change（继承本 change 的 capabilities），命名 `ux-fix-<area>-<round>`：

- `ux-fix-data-integrity-r1`
- `ux-fix-live-workout-interaction-r1`
- `ux-fix-color-tokens-r1`
- `ux-fix-pr-celebration-r1`
- `ux-fix-cmj-watch-entry-r1`
- 等等
