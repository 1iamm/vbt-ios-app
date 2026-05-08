## ADDED Requirements

### Requirement: PaperCitation 结构

The system SHALL define a `PaperCitation` struct in `Shared/Citations/PaperCitation.swift` with these fields:

- `id: String` (e.g. `"gonzalezBadillo2010"`)
- `authors: String` (e.g. `"González-Badillo, J.J., Sánchez-Medina, L."`)
- `year: Int` (e.g. `2010`)
- `title: String`
- `journal: String`
- `doi: String?`
- `url: String` (a stable URL — PubMed, PMC, or DOI)
- `topic: CitationTopic` enum (`.appleWatchValidation / .repDetection / .velocityIntegration / .velocityLoss / .v1RM / .lvpAndE1RM / .velocityVariant / .heartRate / .hrvReadiness / .cmjNeuromuscular`)

#### Scenario: Citation has stable URL

- **WHEN** the runtime reads any `PaperCitation`
- **THEN** `url` is a non-empty string starting with `https://`

### Requirement: V1 必备论文清单

The system SHALL define at minimum these citation constants in `Citations.swift`:

- `balshaw2023AppleWatch` — Apple Watch validation for bench press velocity
- `oReilly2018InertialReview` — Wearable IMU systems review (rep detection)
- `skog2010ZUPT` — ZUPT algorithm evaluation
- `foxlin2005Pedestrian` — Pedestrian tracking with shoe-mounted IMU (ZUPT theory)
- `sanchezMedina2011VL` — VL as fatigue indicator
- `parejaBlanco2017VLEffects` — VL training effects on adaptation
- `gonzalezBadillo2010Velocity` — V1RM reference values
- `jidovtseff2011LVP` — Load-velocity 1RM prediction
- `garciaRamos2018LVPVariants` — LVP differences across exercises
- `sanchezMedina2010Propulsive` — MPV / propulsive phase
- `tanaka2001HRMax` — Age-predicted HRMax revisited
- `plews2013HRV` — HRV in elite endurance
- `flattEsco2016HRV` — Smartphone HRV and training load
- `buchheit2014HR` — Monitoring training status with HR
- `watson2017Sleep` — Sleep and athletic performance
- `claudino2017CMJ` — CMJ for neuromuscular monitoring (meta-analysis)
- `watkins2017CMJReadiness` — CMJ as neuromuscular readiness
- `linthorne2001Jump` — Standing vertical jumps using a force platform (flight-time method)

#### Scenario: All citations have a URL

- **WHEN** the runtime maps `Citations.all.map(\.url)`
- **THEN** every URL starts with `https://`
- **AND** no two citations share the same `id`

### Requirement: Citations 集合访问

The system SHALL expose `enum Citations` with two static accessors:

- `Citations.all: [PaperCitation]` — array of all citations (in any stable order)
- `Citations.byTopic(_ topic: CitationTopic) -> [PaperCitation]` — filtered subset

#### Scenario: Lookup by topic

- **WHEN** `Citations.byTopic(.velocityLoss)` is called
- **THEN** the result contains both `sanchezMedina2011VL` and `parejaBlanco2017VLEffects`

### Requirement: 论文引用在算法代码中可追溯

The system SHALL place a doc comment above any algorithm constant or function that derives from literature, in the format:

```swift
/// Reference: Citations.gonzalezBadillo2010Velocity (V1RM = 0.17 m/s for bench press MPV).
let benchV1RM: Double = 0.17
```

This is a coding convention; the spec verifies it via the rule that every algorithm-related constant in `Algorithms/` (in later proposals) must reference a citation symbol in its doc comment. For Proposal 1 (foundation), the rule applies only to Exercise metadata constants in `ExerciseLibrary.swift`.

#### Scenario: Convention check on ExerciseLibrary

- **WHEN** a developer greps `ExerciseLibrary.swift` for `referenceV1RM`
- **THEN** every assignment of `referenceV1RM` is preceded within 5 lines by a comment referencing `Citations.*`
