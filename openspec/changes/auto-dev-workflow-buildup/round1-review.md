# Pipeline Round 1 Review · 3-Agent 终审报告（PR #9）

> 2026-05-13。Task 1 (`auto-dev-workflow-buildup`) 退出条件之一：3-agent 终审通过。本报告记录 Round 1 评审结果——**全员 NO PASS**，需修复并 Round 2 重审。

## 评审范围

PR #49-#57 累积构建的流水线：
- `ci.yml` 主 pipeline（fast-fail + build-test）
- `claude.yml` Claude bot
- `format-baseline.yml` 一次性格式化
- `scripts/{check-structure,verify}.sh`
- PR template / CODEOWNERS / OpenSpec mandate

## 3 Agent 视角分工

| Agent | 视角 | Findings | Verdict |
|---|---|---|---|
| **DX** | 云端 AI 开发者（无 PAT / 无 gh） | 15（2 P0 / 6 P1 / 7 P2）| ❌ NO PASS |
| **Reliability** | 失败检出率 / 误报 / 盲洞 | 15（4 P0 / 4 P1 / 7 P2）| ❌ NO PASS |
| **Cost** | macOS 分钟 / wall time | 15（3 P0 / 5 P1 / 7 P2）| ❌ NO PASS |

## 跨 Agent 强信号（多 agent 印证）

| Finding | DX | Reliability | Cost |
|---|:---:|:---:|:---:|
| **docs-only PR 仍跑完整 build** | F8 P1 | — | #2 P0 |
| **CI 失败 dump 覆盖不全**（仅 5 step） | F1-F4 P0 | #14 P2 | — |
| **失败评论不 sticky 堆积** | F5 P0 | — | — |

## P0 行动清单（按 ROI 排序）

| # | 标识 | 内容 | 来源 | 目标 PR |
|---|---|---|---|---|
| 1 | **docs-only PR 跳过 build** | docs/openspec/.md 改动跳过整个 macOS build/test | DX F8 + Cost #2 | PR #61 |
| 2 | **DerivedData cache** | 每 PR 省 3-5 min（一年 ~1000 macOS min）| Cost #1 | PR #62 |
| 3 | **CI 失败 dump 完整化** | 加 brew/xcode-select/sim/release 到 sections + 扩 regex 含 crash/assertion | DX F1+F2+F3 | PR #63 |
| 4 | **失败评论 sticky** | 加 `<!-- ci-failure -->` tag 走 updateComment | DX F5 | PR #63（合并）|
| 5 | **build-for-testing 拆分 + sim boot 并行** | 1-3 min/PR | Cost #3 | PR #64 |
| 6 | **SwiftData migration 测试** | checked-in `seed-v1.store` fixture | Reliability #1 | PR #60 |
| 7 | **修 RepDetector testCleanFiveReps 根因** | 算法在合成 5-rep 信号上检出 3-4 reps（已知坏，被 skip）| Reliability #4 | PR #66 |
| 8 | **WatchConnectivity 契约测试** | 同进程内 roundtrip 所有 message types | Reliability #3 | PR #65 |

## P1 行动清单（次优先级）

详见 3 个 agent 报告原文（agent IDs `aadf63f4...`、`afd5918...`、`a49fde...`，输出归档于 task 文件夹）。包括但不限于：
- `Tests/UITests/` 改动归类细化（DX F14）
- watchOS UI test 完全缺失（Reliability #5）
- Memory leak / ARC 检测（Reliability #6）
- 截图 release tag 长期累积（DX F13 + Reliability #10）
- brew 子命令合并 + xcparse 单独 install 合并（Cost #5）
- 用 `gh release upload --clobber` 代替 delete+create（Cost #7）

## Round 2 触发条件

P0 行动清单全部 done 或 wontfix-rationale 后，再跑一轮 3-agent 评审。Round 2 之后两轮连续 PASS → Task 1 完成。
