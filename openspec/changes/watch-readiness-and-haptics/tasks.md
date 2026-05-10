# Tasks

## Readiness 布局

- [ ] 重写 `VBTrainerWatch Watch App/Views/WatchScreens.swift::WatchReadinessView`
  - [ ] 外层套 `ScrollView`
  - [ ] 圆环 `frame(width: 110, height: 110)`，内中心数字 28pt SF Rounded Bold
  - [ ] 顶部 Spacer 改 12pt
  - [ ] 三列 miniStat 数字字号 12pt，间距 6pt
  - [ ] 「跳过」改为圆环下方 13pt 灰色 Button(role: .cancel) 文本链接
  - [ ] 「CMJ 测试」改为底部全宽 borderedProminent 胶囊（accent 配色）
  - [ ] 删除原底部 HStack 按钮行

## Haptic 合约

- [ ] 改写 `VBTrainerWatch Watch App/Views/HapticFeedback.swift`
  - [ ] 修正 `rep(_:)` 映射：met → `.directionUp`、borderline → `.directionDown`
  - [ ] 新增 `static func setEnded()` → `.stop`
  - [ ] 新增 `static func workoutEnded()` → `.success`
  - [ ] 新增私有 `lastFireAt: Date?` + 180ms 节流（仅 `rep(_)` 内部使用）
  - [ ] `rep(_:)` 调用前读 `UserDefaults.standard.object(forKey: "watch.enableRepHaptic") as? Bool ?? true`，false 时 no-op

## Controller 接通

- [ ] 改 `LiveWorkoutController.apply(_:)`
  - [ ] `.repCompleted` case 末尾追加 `HapticFeedback.rep(status)`
- [ ] 改 `LiveWorkoutController.endSet()`
  - [ ] `await session.endSet()` 之后追加 `HapticFeedback.setEnded()`
- [ ] 改 `LiveWorkoutController.completeWithFeedback(rpe:notes:)`
  - [ ] 在 `WatchConnectivityService.shared.send(...)` 之前调
    `HapticFeedback.workoutEnded()`（保证锁屏立即震动）

## Preference 同步

- [ ] 改 `Shared/Services/ConnectivityProtocol.swift`
  - [ ] 新增 `public struct WatchPreferencesSnapshot: Codable, Sendable, Equatable`
    含 `public var enableRepHaptic: Bool`
  - [ ] 新增 `case preferences(WatchPreferencesSnapshot)` 到 `ConnectivityMessage`
  - [ ] 新增 `case preferences` 到 `ConnectivityKind` enum 并加入 `kind` switch
- [ ] 改 `VBTrainerWatch Watch App/Services/WatchConnectivityService.swift`
  - [ ] `didReceiveUserInfo` switch 加 `.preferences` case，写入
    `UserDefaults.standard.set(snap.enableRepHaptic, forKey: "watch.enableRepHaptic")`
- [ ] 改 iPhone 端 `SettingsView` 或 ProfileEditor：toggle change 事件触发
  `WatchConnectivityService.shared.send(.preferences(...))`
  - [ ] 找到 iPhone 端 send 入口（应该是 `iPhoneConnectivityService` 或类似命名
    的类，复用其 `send(message:)`）

## 验证

- [ ] 跑 `./scripts/verify.sh` 通过
- [ ] commit + push 到 `claude/review-project-alignment-t2lp0` 分支
- [ ] 开 PR 并 ready for review
