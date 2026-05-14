// MainTabsUITest.swift
// VBTrainer · UITests · 2026-05
//
// Visual smoke for the 5 main tabs (Today / Plan / History / Stats /
// Profile). Onboarding is dismissed first so this exercises the actual
// product surface — every PR's screenshot set will then cover the
// screens a user actually sees, not just onboarding.
//
// Each tab gets a `keepAlways` screenshot so PR comments show the full
// 5-tab visual diff per push.
//
// Verifications are lightweight: tab buttons exist by
// accessibilityIdentifier (PR #70 + PR #82 + PR #84 added them). No
// text assertions because copy / mock data may shift.

import XCTest

final class MainTabsUITest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEachMainTabRenders() {
        let app = XCUIApplication()
        app.launchArguments.append("-UI_TEST_MODE")
        app.launch()

        // ── Dismiss onboarding ────────────────────────────────────────
        // We don't re-verify onboarding details here (OnboardingUITest
        // owns that); we just tap through to MainTabsView.
        let continueCTA = app.buttons["onboarding.cta.continue"]
        if continueCTA.waitForExistence(timeout: 12) {
            continueCTA.tap()
            _ = continueCTA.waitForExistence(timeout: 6)
            continueCTA.tap()
            let finishCTA = app.buttons["onboarding.cta.finish"]
            _ = finishCTA.waitForExistence(timeout: 6)
            finishCTA.tap()
        }
        // ── 1 · Today (default tab) ───────────────────────────────────
        let todayTab = app.tabBars.buttons["tab.today"]
        waitForExistence(of: todayTab, in: app, timeout: 8, message: "Today tab button")
        // Already selected — capture immediately.
        attachScreenshot("05-tab-today")

        // ── 2 · Plan ──────────────────────────────────────────────────
        app.tabBars.buttons["tab.plan"].tap()
        // No specific identifier inside Plan to wait on — small sleep
        // for the NavigationStack transition + Plan body to render.
        Thread.sleep(forTimeInterval: 0.7)
        attachScreenshot("06-tab-plan")

        // ── 3 · History ───────────────────────────────────────────────
        app.tabBars.buttons["tab.history"].tap()
        Thread.sleep(forTimeInterval: 0.7)
        attachScreenshot("07-tab-history")

        // ── 4 · Stats ─────────────────────────────────────────────────
        app.tabBars.buttons["tab.stats"].tap()
        Thread.sleep(forTimeInterval: 0.7)
        attachScreenshot("08-tab-stats")

        // ── 5 · Profile ───────────────────────────────────────────────
        app.tabBars.buttons["tab.profile"].tap()
        // Profile edit row was given an identifier in PR #70 — wait
        // for it so we know the view is fully laid out before snap.
        let editRow = app.buttons["profile.editProfileRow"]
        _ = editRow.waitForExistence(timeout: 4)
        attachScreenshot("09-tab-profile")
    }
}
