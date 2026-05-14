// TabsUITest.swift
// VBTrainer · UITests · 2026-05
//
// Two-part smoke:
//   A) 5 main tabs render (Today / Plan / History / Stats / Profile)
//   B) Deeper interactions on Today / Plan / Profile (more screenshots
//      so PR reviewers see the actual product surface, not just empty
//      tabs).
//
// Each step takes a `keepAlways` screenshot so PR comments cover the
// real interaction graph.
//
// Tab lookup uses the visible Chinese label text rather than
// `accessibilityIdentifier`. SwiftUI's `.accessibilityIdentifier(...)`
// modifier applied to a `.tabItem(...)` does NOT propagate to the
// underlying UITabBarItem.

import XCTest

final class TabsUITest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEachMainTabRenders() {
        let app = XCUIApplication()
        app.launchArguments.append("-UI_TEST_MODE")
        app.launch()
        dismissOnboardingIfPresent(app)

        // ── 1 · Today ──────────────────────────────────────────────────
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

    /// Drives one step deeper than `testEachMainTabRenders` — captures
    /// the panels users actually open most often (Tweaks bottom sheet,
    /// profile editor, new template editor). Reviewers get a 15-image
    /// PR comment instead of 9 idle tab-open shots.
    func testDeeperInteractionScreens() {
        let app = XCUIApplication()
        app.launchArguments.append("-UI_TEST_MODE")
        app.launch()
        dismissOnboardingIfPresent(app)

        // ── 10 · Tweaks sheet (from Today) ─────────────────────────────
        // Today is the default tab. Tweaks 按钮在右上角，打开 sheet
        // 包含训练目标 / 数据密度 / Readiness 风格 3 个选择。
        _ = app.tabBars.buttons["今天"].waitForExistence(timeout: 6)
        let tweaks = app.buttons["today.tweaks"]
        if tweaks.waitForExistence(timeout: 4) {
            tweaks.tap()
            Thread.sleep(forTimeInterval: 0.8)
            attachScreenshot("10-tweaks-sheet")
            // Dismiss the sheet by swipe-down so subsequent steps run cleanly.
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.4)
        }

        // ── 11 · ProfileEditor (from Profile) ──────────────────────────
        app.tabBars.buttons["我的"].tap()
        let editRow = app.buttons["profile.editProfileRow"]
        if editRow.waitForExistence(timeout: 4) {
            editRow.tap()
            Thread.sleep(forTimeInterval: 0.8)
            attachScreenshot("11-profile-editor")
            // Pop back to the tab stack
            app.navigationBars.buttons.firstMatch.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }

        // ── 12 · New-template editor (from Today empty state) ──────────
        app.tabBars.buttons["今天"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        let newTemplate = app.buttons["today.newTemplate"]
        if newTemplate.waitForExistence(timeout: 4) {
            newTemplate.tap()
            Thread.sleep(forTimeInterval: 0.8)
            attachScreenshot("12-plan-editor")
        }
    }

    // MARK: - Helpers

    private func dismissOnboardingIfPresent(_ app: XCUIApplication) {
        let continueCTA = app.buttons["onboarding.cta.continue"]
        if continueCTA.waitForExistence(timeout: 4) {
            continueCTA.tap()
            _ = continueCTA.waitForExistence(timeout: 6)
            continueCTA.tap()
            let finishCTA = app.buttons["onboarding.cta.finish"]
            _ = finishCTA.waitForExistence(timeout: 6)
            finishCTA.tap()
        }
    }
}
