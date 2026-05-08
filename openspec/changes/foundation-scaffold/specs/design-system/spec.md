## ADDED Requirements

### Requirement: 设计 Token 命名空间

The system SHALL provide design tokens through a namespaced Swift `enum Tokens` with sub-namespaces for `Color`, `Space`, `Radius`, `Font`. Tokens MUST be compile-time constants (no runtime mutation).

#### Scenario: Token usage from any view

- **WHEN** a SwiftUI view references `Tokens.Color.accent`
- **THEN** the value resolves to the orange `#FF9500`
- **AND** the call site does not need to import any third-party package

### Requirement: 颜色 Token 与设计稿一致

The system SHALL define color tokens whose hex values exactly match `design/iphone/.../vbt-tokens.jsx` source-of-truth.

Required colors (from `vbt-tokens.jsx` `VBT.accent` and `VBT.data`):
- `accent` = `#FF9500`
- `Data.heartRate` = `#FF3B30`
- `Data.velocity` = `#0A84FF`
- `Data.volume` = `#FF9500`
- `Data.velocityLoss` = `#BF5AF2`
- `Data.sleep` = `#5E5CE6`

Neutral tokens (`label`, `secondaryLabel`, `bg`, `groupedBg`, `card`, `separator`) MUST resolve through SwiftUI system semantic colors so they auto-adapt to light/dark mode.

#### Scenario: Accent color renders correctly

- **WHEN** a view uses `Tokens.Color.accent`
- **THEN** the rendered color is `#FF9500` in both light and dark modes

#### Scenario: Data color palette is the only data palette

- **WHEN** the project is searched for any chart-related Color literal
- **THEN** all chart colors come from `Tokens.Color.Data.*`
- **AND** no chart introduces additional data colors

### Requirement: 间距 Token (4-pt 制)

The system SHALL define spacing tokens following a 4-point scale matching `vbt-tokens.jsx` `VBT.s`:

- `xs` = 4
- `sm` = 8
- `md` = 12
- `lg` = 16
- `xl` = 20
- `xxl` = 24
- `xxxl` = 32

#### Scenario: Spacing usage

- **WHEN** any view uses padding, spacing, or offsets
- **THEN** the value comes from `Tokens.Space.*`

### Requirement: 圆角 Token

The system SHALL define corner-radius tokens matching `vbt-tokens.jsx` `VBT.r`:

- `sm` = 8
- `md` = 12
- `lg` = 16
- `xl` = 20
- `card` = 14

#### Scenario: Card uses card radius

- **WHEN** a "card" UI element is rendered
- **THEN** its `cornerRadius` is `Tokens.Radius.card` (14)

### Requirement: 字体 Token

The system SHALL define font tokens using SF Pro and SF Pro Rounded, with these styles:

- `Tokens.Font.largeTitle` (34pt, Bold) — page titles
- `Tokens.Font.title` (28pt, Bold)
- `Tokens.Font.headline` (17pt, Semibold)
- `Tokens.Font.body` (17pt, Regular)
- `Tokens.Font.footnote` (13pt, Regular)
- `Tokens.Font.numericLarge` (56-72pt, Rounded Bold) — for stat numbers
- `Tokens.Font.numericMedium` (28pt, Rounded Semibold)

All font tokens MUST support Dynamic Type via `Font.system(size:weight:design:)`.

#### Scenario: Numeric font uses Rounded design

- **WHEN** `Tokens.Font.numericLarge` is applied
- **THEN** the font design is `.rounded` (SF Pro Rounded)

### Requirement: hex 颜色辅助初始化器

The system SHALL provide a `Color(hex: String)` extension supporting 6-digit hex strings (with or without `#` prefix).

#### Scenario: Hex string parses

- **WHEN** code calls `Color(hex: "FF9500")` or `Color(hex: "#FF9500")`
- **THEN** the result equals `Color(red: 1.0, green: 149/255, blue: 0)`
