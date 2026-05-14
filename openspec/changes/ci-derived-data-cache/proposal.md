# Proposal: DerivedData 跨 PR 缓存

## Why

Round 1 review · Cost #1 (P0)：

> 每 PR 都从零编译 iOS + watchOS（~3-5 min wall time）。`~/Library/Developer/Xcode/DerivedData` 没有任何 `actions/cache` 命中。即使是只改 docs 的 PR（PR #60 已跳过），native code PR 仍每次冷编。一年按 200 PR 算浪费 600-1000 macOS 分钟。

## What Changes

`.github/workflows/ci.yml`：在 `Install xcodegen + linters` 之后、`Generate Xcode project` 之前插入：

```yaml
- name: Cache DerivedData (incremental compile)
  uses: actions/cache@v4
  with:
    path: |
      ~/Library/Developer/Xcode/DerivedData
      ~/Library/Developer/Xcode/SDKStatCaches.noindex
    key: derived-${{ runner.os }}-xcode26-${{ hashFiles('project.yml', '**/*.swift') }}
    restore-keys: |
      derived-${{ runner.os }}-xcode26-
```

## 缓存策略要点

- **Path 包含**：`DerivedData/`（编译产物）+ `SDKStatCaches.noindex`（SDK header stat 缓存，单独 ~100MB）
- **不包含 `ModuleCache.noindex`**：Xcode 自动生成，跨 cache hit 可能产生奇怪状态（已知坑）
- **Key 用 hashFiles**：`project.yml` + 所有 `.swift` 文件内容哈希。任一改动 → 新 key → cold path
- **restore-keys**：精确不命中时回退到任何 `derived-macOS-xcode26-` 前缀的旧缓存，作为增量编译起点。Xcode 增量编译器会逐文件失效

## Capabilities

### Modified Capabilities
- `ci-fast-build`

## Impact

- 首次 push 后缓存冷：本 PR 自己不省时间
- 第 2 个 PR 起：精确 key 命中省 ~3-5 min；不命中时增量编译省 ~1-3 min
- 一年累积估计 ~600-1000 macOS 分钟

## Risk

- **缓存损坏**：若 Xcode 残留状态污染，新 PR 编译失败。**应对**：清缓存只需调整 `xcode26` → `xcode27` 等版本标签（cache key 整体改变）
- **缓存膨胀**：每个 unique key 一份缓存，GitHub Actions 缓存 10GB 上限。**应对**：actions/cache 自动 LRU 驱逐
- **iOS vs watchOS 混淆**：同一 DerivedData 目录两个 target，cache 共享。已观察现有 ci.yml 正常工作

## Exit Criteria

- 本 PR 合并后，第 2 次 native-code PR 的 macOS build wall time **降到 < 5 min**（vs 当前 ~8 min）
- 编译失败率不增加
