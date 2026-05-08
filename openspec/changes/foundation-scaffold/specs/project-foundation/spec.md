## ADDED Requirements

### Requirement: Xcode 双 Target 工程结构

The system SHALL provide a single Xcode project `VBTrainer.xcodeproj` containing two targets: an iOS app target and a watchOS app target, configured as a Modern Watch App pair.

#### Scenario: Open project in Xcode

- **WHEN** a developer runs `open /Users/lizexi/workspace/vbt/VBTrainer.xcodeproj`
- **THEN** Xcode opens the project showing two schemes: `VBTrainer` (iOS) and `VBTrainerWatch Watch App` (watchOS)
- **AND** the build folder structure includes `VBTrainer/`, `VBTrainerWatch Watch App/`, `Shared/` directories

#### Scenario: Both targets compile after scaffold

- **WHEN** the developer selects the `VBTrainer` scheme and presses Build (⌘B) with any iPhone simulator
- **THEN** the build succeeds with no errors
- **WHEN** the developer selects the `VBTrainerWatch Watch App` scheme and presses Build with any Apple Watch simulator
- **THEN** the build succeeds with no errors

### Requirement: Bundle ID 与签名配置

The system SHALL configure Bundle Identifiers and signing for personal-team development.

- iOS Bundle ID: `com.vbtrainer.app`
- watchOS Bundle ID: `com.vbtrainer.app.watchkitapp`
- Code signing: automatic, using the user's Personal Team
- Deployment targets: iOS 16.0, watchOS 9.0

#### Scenario: Bundle ID is configured

- **WHEN** the developer opens "Signing & Capabilities" for either target
- **THEN** the Bundle Identifier matches the values above
- **AND** the deployment target matches the values above

### Requirement: Info.plist 权限声明

The system SHALL declare the privacy usage descriptions required for sensors and HealthKit.

watchOS target Info.plist MUST contain:
- `NSMotionUsageDescription` (Chinese description for IMU data collection)
- `NSHealthShareUsageDescription` (read heart rate, sleep, HRV, temperature)
- `NSHealthUpdateUsageDescription` (write Workout records)

iOS target Info.plist MUST contain the same three keys.

#### Scenario: Privacy strings present

- **WHEN** Xcode validates the Info.plist of either target
- **THEN** all three required keys are present with non-empty Chinese strings

### Requirement: 项目目录结构

The system SHALL organize source files in a flat, conventional structure:

```
VBTrainer/                     ← iOS app target
  App/VBTrainerApp.swift
  Views/                       ← (filled by later proposals)
  Services/
  Resources/Assets.xcassets
  Resources/Info.plist
  Resources/Localizable.xcstrings

VBTrainerWatch Watch App/      ← watchOS app target
  App/VBTrainerWatchApp.swift
  Views/
  Sensors/
  Algorithms/
  Services/
  Resources/Assets.xcassets
  Resources/Info.plist

Shared/                        ← both targets
  Models/                      ← @Model classes
  Theme/                       ← Tokens.swift, Color+Hex.swift
  ExerciseLibrary/             ← Exercise.swift, exerciseLibrary array
  Citations/                   ← PaperCitation.swift, Citations.swift
  Extensions/
```

#### Scenario: Shared folder is in both targets

- **WHEN** the developer inspects target membership of any file under `Shared/`
- **THEN** the file appears in both `VBTrainer` and `VBTrainerWatch Watch App` target membership

### Requirement: 项目级 README

The system SHALL provide a `README.md` at project root explaining how to open, sign, and deploy the project to a real device.

The README MUST include:
- Prerequisites (macOS, Xcode version)
- Open / build instructions
- Signing setup (selecting Personal Team)
- Real-device deployment steps (cable, trust profile, 7-day cert renewal)
- Notes that simulator cannot test IMU sensors
- Pointers to PRD and OpenSpec changes

#### Scenario: README exists and is non-trivial

- **WHEN** the developer reads `README.md`
- **THEN** all of the above sections are present and non-empty
