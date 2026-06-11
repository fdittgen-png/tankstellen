// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Host-side bridge for the trip-recording / approach-radar Live Activity
// (#3170), serving the `tankstellen/live_activity` MethodChannel — the
// iOS counterpart of Android's `MainActivity` PiP channel
// (`tankstellen/pip`).
//
// The Dart side (`LiveActivityController` in
// lib/features/consumption/data/live_activity_controller.dart) sends
// pre-formatted `ContentState` payloads; this bridge owns the ActivityKit
// lifecycle: request on `start`, push on `update`, immediate dismissal on
// `end`. The views live in the TankstellenWidget extension
// (`TripRecordingLiveActivity.swift`); the shared
// `TripActivityAttributes` type is compiled into both targets (wired by
// scripts/add_live_activity_sources.rb).
//
// Unlike the older ShareIntentBridge/VisionOcrBridge (kept inline in
// AppDelegate.swift to avoid a pbxproj edit), this lives in its own file:
// since #3166/PR #3217 the project owns reproducible pbxproj wiring
// scripts, so new Swift files are first-class.

import ActivityKit
import Flutter
import Foundation

final class LiveActivityBridge {
    static let shared = LiveActivityBridge()
    private static let channelName = "tankstellen/live_activity"

    /// Content is refreshed at most every ~30 s by the Dart throttle; a
    /// generous stale horizon dims the surface if the app dies mid-trip
    /// without ending the activity.
    private static let staleAfter: TimeInterval = 30 * 60

    private var activity: Activity<TripActivityAttributes>?

    func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(false)
                return
            }
            let args = call.arguments as? [String: Any] ?? [:]
            switch call.method {
            case "start":
                result(self.start(args))
            case "update":
                self.update(args)
                result(nil)
            case "end":
                self.end()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// Requests a fresh activity (ending any survivor first — at most one
    /// trip surface exists). Returns false when the user disabled Live
    /// Activities or ActivityKit vetoed the request; the Dart coordinator
    /// then stays quiet for the rest of the trip.
    private func start(_ args: [String: Any]) -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return false
        }
        end()
        do {
            activity = try Activity.request(
                attributes: TripActivityAttributes(),
                content: ActivityContent(
                    state: Self.contentState(from: args),
                    staleDate: Date().addingTimeInterval(Self.staleAfter)
                )
            )
            return true
        } catch {
            return false
        }
    }

    private func update(_ args: [String: Any]) {
        guard let activity else { return }
        let content = ActivityContent(
            state: Self.contentState(from: args),
            staleDate: Date().addingTimeInterval(Self.staleAfter)
        )
        Task { await activity.update(content) }
    }

    /// Ends EVERY activity of this type, not just the tracked one — a
    /// previous process may have stranded an activity on the lock screen
    /// (crash mid-trip); trip end is the reconciliation point.
    private func end() {
        let survivors = Activity<TripActivityAttributes>.activities
        activity = nil
        guard !survivors.isEmpty else { return }
        Task {
            for survivor in survivors {
                await survivor.end(
                    survivor.content, dismissalPolicy: .immediate)
            }
        }
    }

    /// Decodes the Dart `LiveActivityContent.toChannelMap()` payload.
    /// Defaults are defensive — a malformed field degrades the readout,
    /// never the activity.
    private static func contentState(
        from args: [String: Any]
    ) -> TripActivityAttributes.ContentState {
        TripActivityAttributes.ContentState(
            mode: args["mode"] as? String ?? "recording",
            paused: args["paused"] as? Bool ?? false,
            startedAtEpochMs: (args["startedAtEpochMs"] as? NSNumber)?
                .int64Value
                ?? Int64(Date().timeIntervalSince1970 * 1000),
            bigFigure: args["bigFigure"] as? String ?? "~",
            bigCaption: args["bigCaption"] as? String ?? "",
            isEstimate: args["isEstimate"] as? Bool ?? false,
            distanceText: args["distanceText"] as? String,
            pausedLabel: args["pausedLabel"] as? String ?? "Paused",
            stationName: args["stationName"] as? String,
            priceText: args["priceText"] as? String,
            fuelLabel: args["fuelLabel"] as? String,
            stationDistanceText: args["stationDistanceText"] as? String,
            progress: (args["progress"] as? NSNumber)?.doubleValue
        )
    }
}
