// TabsUITest.swift
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
// Tab lookup uses the visible Chinese label text rather than
// `accessibilityIdentifier`. SwiftUI's `.accessibilityIdentifier(...)`
// modifier applied to a `.tabItem(...)` does NOT propagate to the
// underlying UITabBarItem (verified by first CI run on PR #98 where
// `tab.today` was never found). Labels are stable product copy and
// surface correctly on the tab bar.

import XCTest

final class TabsUITest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEachMainTabRenders() {
        let app = XCUIApplication()
        app.launchArguments.append("-UI_TEST_MODE")
        app.launch()

        // ── Dismiss onboarding IF it's showing ─────────────────────────
        // OnboardingUITest may have already run in this session and
        // persisted a UserProfile, so the app could launch straight into
        // MainTabsView. Treat onboarding as optional. Short timeout (4s)
        // — if no CTA appears we're already in MainTabsView.
        let continueCTA = app.buttons["onboarding.cta.continue"]
        if continueCTA.waitForExistence(timeout: 4) {
            continueCTA.tap()
            _ = continueCTA.waitForExistence(timeout: 6)
            continueCTA.tap()
            let finishCTA = app.buttons["onboarding.cta.finish"]
            _ = finishCTA.waitForExistence(timeout: 6)
            finishCTA.tap()
        }

        // ── 1 · Today (default tab) ────────────────────────────────────
        let todayTab = app.tabBars.buttons["今天"]
        waitForExistence(of: todayTab, in: app, timeout: 8, message: "Today tab (by label)")
        attachScreenshot("05-tab-today")

        // ── 2 · Plan ───────────────────────────────────────────────────
        app.tabBars.buttons["计划"].tap()
        Thread.sleep(forTimeInterval: 0.7)
        attachScreenshot("06-tab-plan")

        // ── 3 · History ────────────────────────────────────────────────
        app.tabBars.buttons["历史"].tap()
        Thread.sleep(forTimeInterval: 0.7)
        attachScreenshot("07-tab-history")

        // ── 4 · Stats ──────────────────────────────────────────────────
        app.tabBars.buttons["统计"].tap()
        Thread.sleep(forTimeInterval: 0.7)
        attachScreenshot("08-tab-stats")

        // ── 5 · Profile ────────────────────────────────────────────────
        app.tabBars.buttons["我的"].tap()
        let editRow = app.buttons["profile.editProfileRow"]
        _ = editRow.waitForExistence(timeout: 4)
        attachScreenshot("09-tab-profile")
    }
}
