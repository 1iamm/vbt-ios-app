## 1. 协议层

- [x] 1.1 `Shared/Services/ConnectivityProtocol.swift` 加 `TemplateSetSpecSnapshot`
- [x] 1.2 `TemplateItemSnapshot` 加 `setSpecs` 字段（默认 `[]`）+ `paramsForSet/effectiveWorkSetCount/totalSetCount` helper
- [x] 1.3 `Shared/Services/TemplateSyncService.swift` 序列化 `orderedSetSpecs` 进 snapshot

## 2. Watch controller plan-aware

- [x] 2.1 加 `plannedSpecs / plannedSetCursor / lastResolvedRest`
- [x] 2.2 加 `preparePlanned(item:)` 把 snapshot 灌进 controller
- [x] 2.3 `start(...)` plan 模式下保留 preparePlanned 字段
- [x] 2.4 `endSet()` 自增 cursor
- [x] 2.5 `startNextSet()` 改可选参数 + 默认从 plannedSpecs 拉
- [x] 2.6 `complete()` 清理 plannedSpecs

## 3. Watch UI

- [x] 3.1 `WatchPlanProgressView` 改为可折叠展开式列表
- [x] 3.2 展开后显示每组 `tag · weight × reps · rest`
- [x] 3.3 "开始本动作" 按钮：preparePlanned + push `.liveWorkout`
- [x] 3.4 `WatchRestView` "下一组" 改为无参 `startNextSet()`

## 4. 编译/验证（用户在 macOS 本机）
- [ ] 4.1 `xcodebuild` 双 target 通过
- [ ] 4.2 真机：iPhone Plan 编辑器配置金字塔 → Watch 收到 → PlanProgress 展开看到每组不同 kg → 开始本动作 → 第 1 组用 50% × top → endSet → Rest "下一组" 跳到 70% × top
