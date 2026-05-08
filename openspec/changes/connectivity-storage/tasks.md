## 1. Storage layer

- [x] 1.1 `Shared/Services/WorkoutStore.swift` — Snapshot ↔ SwiftData
- [x] 1.2 `Shared/Services/JumpTestStore.swift`
- [x] 1.3 `Shared/Services/ReadinessStore.swift`
- [x] 1.4 修改 `Shared/Models/Workout.swift` 加 `heartRateSamplesData: Data?` 存心率序列

## 2. Connectivity protocol

- [x] 2.1 `Shared/Services/ConnectivityProtocol.swift` — `ConnectivityMessage` Codable enum + `Notification.Name.vbtWorkoutImported`

## 3. Watch side

- [x] 3.1 `VBTrainerWatch Watch App/Services/WatchConnectivityService.swift` — WCSessionDelegate + send

## 4. iPhone side

- [x] 4.1 `VBTrainer/Services/iPhoneConnectivityService.swift` — WCSessionDelegate + receive + auto save
- [x] 4.2 修改 `VBTrainerApp.swift` 注入 service

## 5. Build verification

- [x] 5.1 xcodegen + 编译两端 → BUILD SUCCEEDED
- [x] 5.2 `openspec status` 显示全 done
