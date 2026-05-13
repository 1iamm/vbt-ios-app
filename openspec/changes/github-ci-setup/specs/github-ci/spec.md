## ADDED Requirements

### Requirement: PR triggers iOS + watchOS build verification

The repository SHALL run a GitHub Actions job on every `pull_request` event (types `opened`, `synchronize`, `reopened`) that builds both the `VBTrainer` (iOS) and `VBTrainerWatch Watch App` (watchOS) schemes against the simulator SDKs with `CODE_SIGNING_ALLOWED=NO`.

#### Scenario: New PR opened

- **WHEN** a contributor opens a PR against `main`
- **THEN** the `build-test` job under `ci.yml` runs on `macos-26`
- **AND** it installs `xcodegen` via Homebrew, regenerates the `.xcodeproj`, then runs `xcodebuild build` for both targets
- **AND** PR status check `CI / build-test` reflects success/failure

#### Scenario: Force-push to an open PR

- **WHEN** a contributor force-pushes new commits to an open PR
- **THEN** CI re-runs from a clean checkout (no cache assumptions about `.xcodeproj`)

### Requirement: PR triggers algorithm unit tests

After build succeeds, the same job SHALL run `xcodebuild test` scoped to `-only-testing:AlgorithmTests` on the iOS simulator.

#### Scenario: All 7 algorithm test suites pass

- **WHEN** the build step succeeds
- **THEN** `xcodebuild test -only-testing:AlgorithmTests` runs against an iPhone simulator destination
- **AND** any test failure marks the PR check as failed

### Requirement: Claude Code Action reviews every PR

A second workflow `claude.yml` SHALL trigger on `pull_request` (`opened`, `synchronize`) and run `anthropics/claude-code-action@v1` on `ubuntu-latest`, authenticated via the `CLAUDE_CODE_OAUTH_TOKEN` repository secret.

#### Scenario: PR auto-review

- **WHEN** a PR is opened or updated
- **THEN** Claude reads `.claude/CLAUDE.md` and the PR diff, then posts a review comment
- **AND** the review focuses on: paper citation comments on algorithm constants, SwiftData `@Model` schema changes, Shared/ cross-platform impact, missing unit tests

#### Scenario: Missing OAuth token

- **WHEN** the secret `CLAUDE_CODE_OAUTH_TOKEN` is absent or expired
- **THEN** the `claude` job fails, but the PR's required check `CI / build-test` is still green and the PR can be merged
- **AND** maintainer regenerates the token via local `claude setup-token` and updates the secret

### Requirement: `@claude` mention enables interactive coding

The `claude.yml` workflow SHALL also trigger on `issue_comment` and `pull_request_review_comment` events whose body contains the literal string `@claude`.

#### Scenario: Ask Claude to add tests

- **WHEN** the maintainer comments `@claude add unit tests for BarVelocityCalculator` on a PR
- **THEN** Claude Code Action runs, writes new test files, commits to the PR branch with co-author trailer, and replies with what it did
- **AND** the subsequent `synchronize` event re-runs `ci.yml` to validate the new tests

#### Scenario: Comment without @claude

- **WHEN** a maintainer comments `LGTM` (no `@claude` mention)
- **THEN** `claude.yml` does NOT execute

### Requirement: CI does not require code signing

Build and test steps SHALL set `CODE_SIGNING_ALLOWED=NO` and SHALL NOT load `Signing.xcconfig` secrets, because personal Apple Developer certs are not stored in CI.

#### Scenario: CI runs without DEVELOPMENT_TEAM

- **WHEN** ci.yml runs on a fresh `macos-26` runner with no signing credentials
- **THEN** both `xcodebuild build` invocations complete successfully because `CODE_SIGNING_ALLOWED=NO` is passed

### Requirement: Contributing guide documents `@claude` usage and token rotation

`CONTRIBUTING.md` at the repo root SHALL describe:
1. How to invoke `@claude` in PR comments with concrete examples
2. How to rotate `CLAUDE_CODE_OAUTH_TOKEN` when it expires
3. The boundary of what CI does vs. what stays local (no XCUITest E2E in CI)

#### Scenario: New contributor reads CONTRIBUTING.md

- **WHEN** a new contributor opens `CONTRIBUTING.md`
- **THEN** they see at least one `@claude` invocation example, the `claude setup-token` rotation instructions, and the explicit list of what CI does not cover
