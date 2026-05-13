# Tasks: CI 加速

- [x] 新增 `Detect change scope` step（github-script + listFiles + regex）
- [x] 新增 `Cache Homebrew downloads` step（actions/cache@v4）
- [x] 给 5 个 UI test 相关 step 加 `if: steps.changes.outputs.has_ui == 'true'`
- [x] 写 proposal + tasks
- [ ] CI dogfood：本 PR 应跳过 UI test（仅改 ci.yml + openspec）→ < 4 min 跑完
- [ ] 下个 UI PR 验证完整流程仍跑通

## 后续优化（拆分到 PR #6.5 或纳入 PR #7+）

- DerivedData 缓存（带 project.yml hash key）——风险较高，单独 PR 验证
- iOS / watchOS build 并行（拆 jobs）——成本翻倍但时间砍半
- Conditional algorithm test（如果只动 docs，algorithm test 也可跳过）
