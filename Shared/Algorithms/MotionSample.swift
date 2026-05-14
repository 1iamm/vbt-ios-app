// MotionSample.swift
// VBTrainer · watchOS · 2026-05
//
// Single sample emitted by MotionManager. Value type, Sendable.

import Foundation
import simd

public struct MotionSample: Sendable, Equatable {
    /// Monotonic timestamp in seconds (CMDeviceMotion.timestamp is monotonic since boot).
    public let timestamp: TimeInterval

    /// Linear acceleration in m/s², gravity already removed.
    /// CoreMotion delivers `userAcceleration` in g; we convert to m/s² up front.
    public let userAccel: SIMD3<Double>

    /// Attitude quaternion (device → reference frame).
    public let attitude: simd_quatd

    public init(
        timestamp: TimeInterval,
        userAccel: SIMD3<Double>,
        attitude: simd_quatd
    ) {
        self.timestamp = timestamp
        self.userAccel = userAccel
        self.attitude = attitude
    }
}

public extension MotionSample {
    /// Returns the gravity-aligned (world-frame) vertical acceleration in m/s².
    /// V1 simplification: assume the watch face is roughly horizontal during
    /// concentric/eccentric phases of vertical lifts (squat/bench/deadlift),
    /// so device-z aligns with world-vertical to first order. For lifts with
    /// significant wrist rotation we'd need full attitude rotation — flagged
    /// for V2 calibration pass.
    var verticalAccel: Double {
        userAccel.z
    }
}
