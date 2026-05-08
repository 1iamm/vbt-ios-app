## 1. Sync protocol

- [x] 1.1 扩展 `Shared/Services/ConnectivityProtocol.swift` 加 TemplateSnapshot
- [x] 1.2 `Shared/Services/TemplateSyncService.swift` — 推送编排
- [x] 1.3 `iPhoneConnectivityService` 完善 `.template` 推送 send

## 2. Watch 端

- [x] 2.1 `VBTrainerWatch Watch App/Services/TodayPlanLoader.swift`
- [x] 2.2 `WatchConnectivityService` 处理收到的 .template 持久化
- [x] 2.3 修改 `WatchHomeView` 显示今日计划卡片
- [x] 2.4 修改 `WatchPlanProgressView` / `WatchPlanNextView` 改用真实数据

## 3. iPhone 端

- [x] 3.1 修改 `CalendarPlanView` — 挂载时立即调 TemplateSyncService.push

## 4. 编译

- [x] 4.1 xcodegen + 两端 BUILD SUCCEEDED
- [x] 4.2 openspec status 全 done
