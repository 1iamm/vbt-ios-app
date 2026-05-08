## ADDED Requirements

### Requirement: 论文清单页面

`CitationsListView` SHALL display all `Citations.all` entries grouped by `CitationTopic`, each entry showing authors+year+title and tappable to open the URL in Safari.

#### Scenario: Tap opens URL

- **WHEN** the user taps a citation row
- **THEN** Safari opens the citation's URL
