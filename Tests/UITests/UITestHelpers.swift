// UITestHelpers.swift
// VBTrainer · UITests · 2026-05
//
// Tiny shared utilities for XCUITest cases. Notably the screenshot
// attachment helper — XCUITest's default screenshot attachment is
// lifetime=.deleteOnSuccess, which means screenshots disappear on
// pass. We always want them retained for the auto-comment dumper
// (PR #5+) to read out of the .xcresult bundle.

import XCTest

extension XCTestCase {
    /// Capture the full-screen screenshot and attach it permanently to
    /// the test result so the xcresult bundle exposes it after success.
    /// `name` shows up in the .xcresult navigator; keep it short and
    /// sortable (e.g. "01-welcome", "02-value-prop").
    func attachScreenshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Wait up to `timeout` seconds for the given element to exist.
    /// Returns true on success, false on timeout (also fails the test).
    @discardableResult
    func waitForExistence(of element: XCUIElement, timeout: TimeInterval = 5, message: String = "") -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists {
            XCTFail("Expected element to exist: \(element.description). \(message)")
        }
        return exists
    }
}
