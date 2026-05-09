# scripts/

## verify.sh — pre-PR sanity check

Linux 容器没有 Xcode/SDK，无法做完整 type-check。这个脚本用 **`swift -frontend -parse`**（语法分析，不需要 SDK）+ **跨文件符号索引启发式** 抓两类常见 bug：

| 类型 | 例子 | 谁抓 |
|---|---|---|
| 大括号/圆括号/语法错 | PR #2 的 `EventKitService.swift` 多余 `}` | step 1 parse |
| 类型被引用但未定义 | PR #4 的 `EmptyStateCard` 删了但 6 处仍在用 | step 2 cross-file |

**抓不到** 的：
- API 签名错误（参数类型不对、调了不存在的方法）— 需要 SDK 才能 type-check
- 返回类型推导失败 — 同上
- SwiftUI ViewBuilder 内部表达式错 — 同上

所以**这个脚本是 "防低级错误" 的安全网，不能替代 macOS 上的 xcodebuild**。

## 用法

```bash
./scripts/verify.sh
```

退出码 0 = 通过；非零 = 有错。

### 在 macOS 上

`xcrun -f swift-frontend` 会自动找到 Xcode 自带的 swift toolchain，零依赖。

### 在 Linux 上

需要先装 Swift toolchain：

```bash
# Ubuntu 22.04+
curl -O https://download.swift.org/swift-5.10.1-release/ubuntu2204/swift-5.10.1-RELEASE/swift-5.10.1-RELEASE-ubuntu22.04.tar.gz
sudo tar -xzf swift-5.10.1-RELEASE-ubuntu22.04.tar.gz -C /opt/
```

脚本会自动在 PATH / `/opt/swift-*/usr/bin/` 找。

## 白名单

`verify-whitelist.txt` 列出所有在项目里**用了但没在项目里定义**的 type（来自 Foundation / SwiftUI / SwiftData / HealthKit / EventKit / WatchConnectivity / CoreMotion / Charts / UIKit / WatchKit 等 Apple 框架）。

如果 verify 报某个 type 找不到：

1. 如果是项目自定义的，写它的 `struct/class/enum/protocol/actor/typealias` 定义
2. 如果是 Apple 框架的，加到 `verify-whitelist.txt`（对应 framework 段落下）

## 推荐工作流

每次 commit 之前手动跑 `./scripts/verify.sh`，或者通过 git pre-push hook：

```bash
echo '#!/usr/bin/env bash
exec ./scripts/verify.sh' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

完整 type-check 只能在 macOS：

```bash
xcodegen generate
xcodebuild -project VBTrainer.xcodeproj -target VBTrainer -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO build
```
