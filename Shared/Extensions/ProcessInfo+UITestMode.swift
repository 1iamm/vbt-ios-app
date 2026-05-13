// ProcessInfo+UITestMode.swift
// VBTrainer · Shared · 2026-05
//
// Single source of truth for "are we running under XCUITest right now?"
// Set by passing `-UI_TEST_MODE` as a launch argument from the UI test.
//
// When true, the app should:
//   - skip HealthKit / authorization prompts (the system sheet halts the runner)
//   - skip Sign in with Apple
//   - use deterministic seed data instead of querying live SwiftData
//
// Why a launch argument (not env var): launch args show up in
// XCUIApplication.launchArguments cleanly and survive the relaunch
// XCUITest performs between tests.

import Foundation

public extension ProcessInfo {
    /// True iff the app was launched by an XCUITest harness via
    /// `app.launchArguments.append("-UI_TEST_MODE")`.
    static var isUITestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_MODE")
    }
}
