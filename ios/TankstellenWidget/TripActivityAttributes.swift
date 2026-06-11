// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Shared ActivityKit attributes for the trip-recording / approach-radar
// Live Activity (#3170) — the iOS-native answer to the Android PiP tile.
//
// Compiled into BOTH the Runner target (which requests/updates/ends the
// activity via `LiveActivityBridge`) and the TankstellenWidget extension
// (which renders it via `TripRecordingLiveActivity`) — ActivityKit
// matches the two processes on this type, so the single source file must
// stay in both targets' compile sources (wired by
// scripts/add_live_activity_sources.rb).
//
// Every user-facing string arrives PRE-FORMATTED from Dart
// (`LiveActivityContent.toChannelMap()` in
// lib/features/consumption/domain/live_activity_content.dart — keep the
// keys in lock-step): the Dart side owns the ARB localization pipeline,
// the Swift views stay dumb renderers, and both surfaces (PiP + Live
// Activity) share one formatting truth.

import ActivityKit
import Foundation

struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// "recording" (consumption hero) or "approach" (station-price
        /// lead) — mirrors the Dart `LiveActivityMode` enum names.
        var mode: String
        var paused: Bool

        /// Wall-clock trip start (epoch ms) — drives the NATIVELY ticking
        /// elapsed timer so the surface stays alive between sparse
        /// content updates.
        var startedAtEpochMs: Int64

        /// Consumption hero ("5.8" / "~7.1" / "~") + caption
        /// ("L/100 km" / "est. L/100 km" / "L/h").
        var bigFigure: String
        var bigCaption: String
        var isEstimate: Bool

        /// "12.3 km" once the trip covered ≥ 0.1 km.
        var distanceText: String?

        /// Localized "Paused" chip label (rendered while `paused`).
        var pausedLabel: String

        // Approach-mode fields (nil in recording mode).
        var stationName: String?
        var priceText: String?
        var fuelLabel: String?
        var stationDistanceText: String?

        /// Radar closeness fill, 0...1 (fuller = closer). nil hides the bar.
        var progress: Double?

        var isApproach: Bool { mode == "approach" }

        var startedAt: Date {
            Date(timeIntervalSince1970: Double(startedAtEpochMs) / 1000.0)
        }

        /// Open-ended interval for `Text(timerInterval:)` — ActivityKit
        /// needs a closed range; a day is far beyond any single trip.
        var elapsedInterval: ClosedRange<Date> {
            let start = startedAt
            return start...start.addingTimeInterval(24 * 60 * 60)
        }
    }
}
