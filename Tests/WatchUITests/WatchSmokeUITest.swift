// WatchSmokeUITest.swift
// VBTrainer · WatchUITests · 2026-05
//
// Minimum-viable Watch UITest: launch the app and capture the root
// view. Mirrors the iPhone OnboardingUITest pattern so PR comments
// surface a "Watch is alive" screenshot on every push that touches
// Watch UI / Sensors / theme / shared models.
//
// Future expansion (when stable):
//   - drive the Start Workout flow (Today → SetReady → Live)
//   - rest countdown
//   - SetResult + Summary
//   - PR celebration

import XCTest

final class WatchSmokeUITest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testWatchRootRenders() {
        let app = XCUIApplication()
        app.launch()

        // First paint window. The Watch app boots into WatchRootView,
        // which immediately shows the home screen. 4s is generous on
        // sim; first-launch can be slow.
        Thread.sleep(forTimeInterval: 4)
        attachScreenshot("20-watch-root")
    }
}
