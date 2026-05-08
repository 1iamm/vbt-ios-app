## ADDED Requirements

### Requirement: SwiftData Schema 全集

The system SHALL define all SwiftData `@Model` classes required by V1 in the `Shared/Models/` folder. The schema includes:

- `UserProfile` (singleton, the user's profile)
- `Workout` (one training session)
- `ExerciseSet` (one set within a workout)
- `Rep` (one rep within a set)
- `JumpTest` (an independent CMJ jump test, not associated with a Workout)
- `ReadinessSnapshot` (one daily readiness measurement)
- `Template` (a user-created training plan template)
- `TemplateItem` (one exercise entry within a template)
- `PersonalRecord` (a PR: max weight / e1RM / max volume / max single-rep velocity / max CMJ height)

#### Scenario: ModelContainer initializes successfully

- **WHEN** the app launches and creates `ModelContainer(for: UserProfile.self, Workout.self, ExerciseSet.self, Rep.self, JumpTest.self, ReadinessSnapshot.self, Template.self, TemplateItem.self, PersonalRecord.self)`
- **THEN** the container is created without error

### Requirement: UserProfile 字段

`UserProfile` SHALL contain:

- `id: UUID` (primary)
- `age: Int`
- `sex: Sex` enum (`.male / .female / .other`)
- `heightCm: Double`
- `weightKg: Double`
- `bodyType: BodyType` enum (5 cases: `.lean / .standard / .stocky / .muscular / .powerlifter`)
- `trainingExperience: TrainingExperience` enum (4 cases: `<1y / 1-3y / 3-5y / >5y`)
- `trainingGoal: TrainingGoal` enum (5 cases: `.muscle / .strength / .power / .fatLoss / .general`)
- `measuredHRMax: Int?` (optional, nil = use Tanaka formula)
- `restingHR: Int?` (optional, nil = pull from HealthKit)
- `weightUnit: WeightUnit` enum (`.kg / .lb`, default `.kg`)
- `crownStep: Double` (default 2.5)
- `defaultRestSeconds: Int` (default 90)
- `vibrationEnabled: Bool` (default true)
- `cmjOnEachWorkout: Bool` (default false)
- `createdAt: Date`
- `updatedAt: Date`

#### Scenario: Default profile values

- **WHEN** a new UserProfile is created with only `age` and `sex`
- **THEN** `weightUnit` defaults to `.kg`, `crownStep` to 2.5, `defaultRestSeconds` to 90, `vibrationEnabled` to true, `cmjOnEachWorkout` to false

### Requirement: Workout / ExerciseSet / Rep 关系

`Workout` SHALL have a one-to-many `sets: [ExerciseSet]` relationship with `.cascade` delete rule. `ExerciseSet` SHALL have a one-to-many `reps: [Rep]` relationship with `.cascade` delete rule.

`Workout` fields:
- `id: UUID`
- `startedAt: Date`
- `endedAt: Date?`
- `exerciseId: String` (references `Exercise.id` from library)
- `notes: String?`
- `rpe: Int?` (1-10, optional subjective rating)
- `linkedTemplateId: UUID?` (if executed from a template)
- `readinessSnapshotId: UUID?` (the readiness measurement at workout start)
- `sets: [ExerciseSet]`

`ExerciseSet` fields:
- `id: UUID`
- `index: Int` (1-based)
- `weightKg: Double`
- `targetReps: Int?`
- `restAfterSeconds: Int`
- `side: Side` enum (`.both / .left / .right`)
- `velocityVariant: VelocityVariant` enum (`.mv / .mpv / .pv`)
- `targetVelocityRange: ClosedRange<Double>?`
- `vlCeiling: Double?` (force-stop threshold, percent)
- `reps: [Rep]`

`Rep` fields:
- `id: UUID`
- `index: Int`
- `meanVelocity: Double` (m/s)
- `peakVelocity: Double` (m/s)
- `meanPropulsiveVelocity: Double?` (m/s, only for variants where the propulsive phase exists)
- `timestamp: Date`
- `metStatus: MetStatus` enum (`.excellent / .met / .borderline / .failed`) — set by velocity vs target range

#### Scenario: Cascade delete

- **WHEN** a Workout is deleted
- **THEN** all its ExerciseSets and Reps are also deleted

### Requirement: JumpTest 独立模型

`JumpTest` SHALL be modeled independently from `Workout` (per PRD: CMJ is for state assessment, not training).

Fields:
- `id: UUID`
- `performedAt: Date`
- `attempts: [Double]` (jump heights in cm, one per attempt — typically 3)
- `bestHeightCm: Double` (max of attempts)
- `flightTimeSeconds: [Double]` (per-attempt flight time)
- `linkedWorkoutId: UUID?` (if performed before a workout)

#### Scenario: Best height computation

- **WHEN** a JumpTest is created with `attempts = [32.1, 33.5, 31.0]`
- **THEN** `bestHeightCm == 33.5`

### Requirement: ReadinessSnapshot 模型

`ReadinessSnapshot` SHALL store a daily readiness measurement.

Fields:
- `id: UUID`
- `date: Date` (start-of-day, used as key)
- `sleepDurationHours: Double?`
- `deepSleepHours: Double?`
- `remSleepHours: Double?`
- `hrv: Double?` (SDNN ms)
- `hrvBaseline: Double?` (7-day rolling)
- `restingHR: Int?`
- `restingHRBaseline: Double?`
- `wristTemperatureDelta: Double?` (Celsius offset from baseline)
- `respiratoryRate: Double?`
- `score: Int?` (computed Readiness Score 0-100, nil if insufficient baseline)
- `tier: ReadinessTier` enum (`.green / .yellow / .red / .insufficient`)

#### Scenario: Date is unique key

- **WHEN** two ReadinessSnapshot records would share the same start-of-day date
- **THEN** the system treats them as the same logical snapshot (later replaces earlier)

### Requirement: Template / TemplateItem 模型

`Template` SHALL store a user-built workout template.

Template fields:
- `id: UUID`
- `name: String`
- `notes: String?`
- `items: [TemplateItem]` (cascade)
- `createdAt: Date`
- `updatedAt: Date`

TemplateItem fields:
- `id: UUID`
- `index: Int`
- `exerciseId: String`
- `targetSets: Int`
- `targetReps: Int`
- `targetWeightKg: Double?`
- `targetVelocityRange: ClosedRange<Double>?`
- `vlCeiling: Double?`
- `restSeconds: Int`
- `side: Side`

#### Scenario: Template execution links Workout

- **WHEN** a Workout is created from a Template
- **THEN** `Workout.linkedTemplateId == Template.id`

### Requirement: PersonalRecord 模型

`PersonalRecord` SHALL track per-exercise records.

Fields:
- `id: UUID`
- `exerciseId: String`
- `kind: PRKind` enum (`.maxWeight / .e1RM / .maxVolume / .maxSingleRepVelocity / .maxCMJ`)
- `value: Double`
- `achievedAt: Date`
- `sourceWorkoutId: UUID?` (or `sourceJumpTestId`)

#### Scenario: PR record on workout completion

- **WHEN** a workout completes with a higher max weight than any prior `.maxWeight` PR for the same exerciseId
- **THEN** a new PersonalRecord with `kind == .maxWeight` is created

### Requirement: Schema 版本化

The system SHALL declare an explicit schema version `1` for V1, using SwiftData `Schema(versionedSchema:)` semantics, to allow non-destructive migration in V2.

#### Scenario: Schema version available

- **WHEN** the app inspects its model container schema
- **THEN** the schema version identifier is `1` (or equivalent semantically)
