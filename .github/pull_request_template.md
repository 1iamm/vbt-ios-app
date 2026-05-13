<!--
PR 标题约定：
  <type>: <subject> [optional-openspec-change-name]

  type 枚举：feat / fix / chore / ci / refactor / docs / test
  示例：
    feat: 添加 onboarding 第 3 步训练目标选择 [onboarding-v4-visual]
    fix: 修复 LiveSet 双启动竞态 [wire-watch-live-session]
    ci: 接入 SwiftLint + SwiftFormat 工具链

下面这些 section 是给人/AI 验收用的，**全部要填**。空着的删掉，不要留 placeholder。
-->

## 📝 本次改动

<!-- 一句话说清这个 PR 做了什么。如果是多个相关变更，列 bullet。 -->

**做了什么**：

**影响范围**：iOS / watchOS / Shared / CI / 全部

**关联 OpenSpec change**：[`<change-name>`](../tree/main/openspec/changes/<change-name>) (如有)

## ✅ 验收步骤

<!--
每一步独立填写。模板：

### 步骤 N · 简短描述

**操作**：（用户/测试在 app 里做什么）
**预期**：
- 看到 X
- 点击 Y 后 Z

**截图**：（PR #4+ 上线后由自动化注入）

**自动检查**：（PR #4+ 上线后由自动化注入；现在手动列）
- ✅ 编译通过
- ✅ XX 单元测试通过

**与上次比对**：⚪️ 无变化 / 🆕 新页面 / ⚠️ 像素差异 X%
-->

### 步骤 1 · 

**操作**：
**预期**：

## 🤖 自动检查

<!-- 填 ✅/❌ 自己确认过的；其余等 CI 跑完打勾 -->

- [ ] iOS 编译
- [ ] watchOS 编译
- [ ] 算法单元测试
- [ ] SwiftLint / SwiftFormat（advisory）
- [ ] 项目结构检查
- [ ] PR 大小 < 800 行

## ⚠️ 风险点

<!--
列出这个 PR 可能破坏的东西。AI 写 PR 时必须主动 surface：
- 既有用户升级后的 schema 兼容性
- 跨端编译（iOS / watchOS 任一坏了就要标）
- 算法常量改动对历史训练数据的影响
- HIG 偏离（如 tap target < 44pt）

写"无"也要写"无"，不要空着。
-->

- 

## 👉 验收 Checklist

- [ ] 看完上面所有截图（PR #4+ 上线后）
- [ ] 风险点都能接受
- [ ] OK 后点 **Merge**
