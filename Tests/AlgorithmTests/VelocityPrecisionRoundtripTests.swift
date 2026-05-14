// VelocityPrecisionRoundtripTests.swift
// VBTrainer · 2026-05
//
// Round 1 IX-F15 (P2): drift guard for cross-device velocity precision.
// The Watch computes velocity from IMU samples, encodes it into a
// WorkoutSnapshot, and the iPhone decodes and displays it. Without a
// round-trip test, a future change to:
//   - SetSnapshot.velocity precision (Double vs Float)
//   - Codable strategy
//   - VelocityVariant enum mapping
// could silently produce a "Watch shows 0.45 m/s but iPhone history
// shows 0.453123" or — worse — wrong unit. This test fixes a sample
// SetSnapshot, encodes it via JSONEncoder (the wire format used by
// transferUserInfo), decodes it back, and asserts bit-exact equality
// on every velocity field.

import XCTest

final class VelocityPrecisionRoundtripTests: XCTestCase {

    /// Per-rep velocities must survive encode/decode without precision loss
    /// across the entire significant range (0.01 m/s — 3.0 m/s).
    func testRepVelocityBitExactRoundtrip() throws {
        let samples: [Double] = [
            0.0,             // boundary
            0.01,            // sub-threshold
            0.17,            // bench MPV @ 1RM (Gonzalez-Badillo 2010)
            0.42,            // typical 5-rep working set
            0.583_172_94,    // arbitrary high-precision
            1.0,             // jump-ish
            2.5,             // upper bound
            -0.42,           // eccentric (signed)
        ]
        for v in samples {
            let rep = RepSnapshot(
                id: UUID(),
                index: 1,
                meanVelocity: v,
                peakVelocity: v * 1.15,
                meanPropulsiveVelocity: v * 0.95,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                metStatus: .met
            )
            let data = try JSONEncoder().encode(rep)
            let decoded = try JSONDecoder().decode(RepSnapshot.self, from: data)
            XCTAssertEqual(rep, decoded, "RepSnapshot roundtrip mismatch for v=\(v)")
            // Bit-exact equality (catch precision loss that Equatable
            // might mask via custom == operators).
            XCTAssertEqual(rep.meanVelocity, decoded.meanVelocity)
            XCTAssertEqual(rep.peakVelocity, decoded.peakVelocity)
            XCTAssertEqual(rep.meanPropulsiveVelocity, decoded.meanPropulsiveVelocity)
        }
    }

    /// A SetSnapshot containing N reps must round-trip — guards against
    /// nested-array Codable bugs.
    func testSetWithRepsRoundtrip() throws {
        let reps = (0 ..< 5).map { i in
            RepSnapshot(
                id: UUID(),
                index: i + 1,
                meanVelocity: 0.5 - Double(i) * 0.02,
                peakVelocity: 0.6 - Double(i) * 0.02,
                meanPropulsiveVelocity: 0.55 - Double(i) * 0.02,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000 + Double(i)),
                metStatus: .met
            )
        }
        let set = SetSnapshot(
            id: UUID(),
            index: 1,
            weightKg: 100,
            velocityVariant: .mv,
            targetRange: 0.45 ... 0.65,
            vlCeiling: 0.20,
            side: .both,
            restAfterSeconds: 120,
            reps: reps
        )

        let data = try JSONEncoder().encode(set)
        let decoded = try JSONDecoder().decode(SetSnapshot.self, from: data)
        XCTAssertEqual(set.reps.count, decoded.reps.count)
        for (a, b) in zip(set.reps, decoded.reps) {
            XCTAssertEqual(a.meanVelocity, b.meanVelocity)
            XCTAssertEqual(a.peakVelocity, b.peakVelocity)
            XCTAssertEqual(a.meanPropulsiveVelocity, b.meanPropulsiveVelocity)
        }
    }
}
