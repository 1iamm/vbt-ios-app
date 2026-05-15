// UITestHelpers.swift
// VBTrainer · WatchUITests · 2026-05
//
// Watch-side counterpart to Tests/UITests/UITestHelpers.swift.
// Same `attachScreenshot` semantics — keepAlways lifetime so the
// .xcresult bundle exposes the PNGs after success, ready for xcparse
// extraction in CI.

import XCTest

extension XCTestCase {
    /// Capture the full-screen screenshot and attach it permanently to
    /// the test result. Use a sortable name (e.g. "20-watch-root").
    func attachScreenshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
