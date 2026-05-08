## ADDED Requirements

### Requirement: Score 公式

The system SHALL provide `ReadinessCalculator.compute(input:) -> ReadinessOutput` with a deterministic formula combining HRV / sleep / RHR / wristTemperature signals.

```
hrvScore   = subscoreFromZScore(hrv vs baseline)         // higher is better
rhrScore   = 100 - subscoreFromZScore(rhr vs baseline)   // lower rhr is better
sleepScore = scoreFromSleep(totalHours, deepHours)
tempScore  = subscoreFromTempDelta(delta)

total = round(0.50*hrvScore + 0.25*sleepScore + 0.20*rhrScore + 0.05*tempScore)
```

References: Citations.plews2013HRV, Citations.flattEsco2016HRV, Citations.watson2017Sleep.

#### Scenario: Baseline missing → insufficient

- **WHEN** input has no baseline (fewer than 5 days of HRV data)
- **THEN** `ReadinessOutput.tier == .insufficient` and `score == nil`

#### Scenario: Perfect day → green

- **WHEN** HRV equals baseline, sleep is 8h with 1.8h deep, rhr equals baseline, temp delta is 0
- **THEN** score is between 80 and 100, tier is `.green`

### Requirement: Tier 映射

The function maps score to tier:
- ≥ 80 → `.green`
- 60–79 → `.yellow`
- < 60 → `.red`
