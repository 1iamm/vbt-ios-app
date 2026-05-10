# Tasks

全部在 `VBTrainerWatch Watch App/Views/WatchScreens.swift` 内。

## 重写 5 个 V2 stub view

- [ ] PlanSyncedView：分组列表 + Crown 滚动 + 当前组高亮 + 已完成置灰
- [ ] SetReadyView：动作名 28pt + 重量 39pt + 32pt 橙色 capsule
- [ ] SetResultView：3 态 + 76pt 圆形图标 + 双格 stat + .task 自动 3s 跳转
- [ ] WorkoutDoneView：4 格 stat + 「同步到 iPhone」绿色 capsule
- [ ] SyncIdleView 视觉略微细化（非主流程，保持现有简洁版即可）

## 重写 V1 view body 到 V2 视觉

- [ ] WatchLiveWorkoutView body 重写：95pt 主数字 + 状态色 + 顶部双行 + 底部红色 capsule
- [ ] WatchRestView body 重写：±10s 圆按钮 + 倒计时环 + 橙色描边下一组卡

## 调整路由跳转

- [ ] WatchLiveWorkoutView「结束本组」改为 push `.setResult` 而非 `.rest`
- [ ] WatchRestView「跳过」改为 push `.setReady`（下一组）或 `.workoutDone`
- [ ] WatchRestView 倒计时归 0 自动跳转

## 验证

- [ ] `./scripts/verify.sh` 通过
- [ ] watch target build 通过
- [ ] 真机：从 PlanSynced 走通一组 → 进 SetReady → LiveSet → SetResult → RestV2 → 下一组 SetReady
