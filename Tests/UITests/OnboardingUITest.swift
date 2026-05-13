// OnboardingUITest.swift
// VBTrainer · UITests · 2026-05
//
// First end-to-end UI test. Walks through the 3-step onboarding flow
// (welcome → value prop → profile) under `-UI_TEST_MODE`, which makes
// the app skip HealthKitPermissionView (its system sheet would halt
// the test runner).
//
// Each step takes a `keepAlways` screenshot so the .xcresult bundle
// exposes them after the test passes — PR #5 will read those out and
// upload to a per-PR GitHub Release for embedding in the auto PR
// comment.
//
// Verification points are intentionally lightweight: existence of the
// CTA button by accessibilityIdentifier. We don't assert text strings
// because copy may change; the accessibility identifier is the stable
// contract.

import XCTest

final class OnboardingUITest: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-UI_TEST_MODE")
        app.launch()

        // ─────────────────────────────────────────────────────────
        // Step 0 — Welcome
        // ─────────────────────────────────────────────────────────
        let continueCTA = app.buttons["onboarding.cta.continue"]
        waitForExistence(of: continueCTA, in: app, timeout: 12, message: "Welcome step CTA")
        attachScreenshot("01-welcome")
        continueCTA.tap()

        // ─────────────────────────────────────────────────────────
        // Step 1 — Value proposition
        // The CTA identifier is still .continue (not the last step).
        // ─────────────────────────────────────────────────────────
        waitForExistence(of: continueCTA, in: app, timeout: 6, message: "Value-prop step CTA")
        attachScreenshot("02-value-prop")
        continueCTA.tap()

        // ─────────────────────────────────────────────────────────
        // Step 2 — Profile (under UI test mode this replaces the
        // HealthKitPermissionView). CTA changes to .finish.
        // ─────────────────────────────────────────────────────────
        let finishCTA = app.buttons["onboarding.cta.finish"]
        waitForExistence(of: finishCTA, in: app, timeout: 6, message: "Profile/finish CTA")
        attachScreenshot("03-profile")
        finishCTA.tap()

        // ─────────────────────────────────────────────────────────
        // Onboarding complete. The TabView root should be on screen.
        // We don't depend on a specific tab name here — only that the
        // onboarding CTA is gone.
        // ─────────────────────────────────────────────────────────
        let done = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: done, object: finishCTA)
        let result = XCTWaiter.wait(for: [expectation], timeout: 4)
        XCTAssertEqual(result, .completed, "Expected onboarding to dismiss but finish CTA still visible.")
        attachScreenshot("04-onboarding-complete")
    }
}
