// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Live Activity views for the trip-recording / approach-radar surface
// (#3170) — lock-screen banner + Dynamic Island (compact / minimal /
// expanded). Registered in `TankstellenWidgetBundle`
// (TankstellenWidget.swift); the Runner side starts/updates/ends the
// activity via `LiveActivityBridge`.
//
// Visual language mirrors the Android PiP tile (#2068 / #2084): a huge
// consumption figure while driving, flipping to a huge station price +
// closeness bar when the Fuel Station Radar / approach detector has a
// target. Elapsed ticks natively via `Text(timerInterval:)` so the
// surface stays alive between the Dart side's sparse content updates.
//
// Localization: every user-facing string arrives pre-localized from the
// Dart ARB pipeline inside `ContentState`; the only literal here is the
// brand name (same convention as `NearestStationsWidgetView`).

import ActivityKit
import SwiftUI
import WidgetKit

struct TripRecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            TripActivityLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "fuelpump.fill")
                            .foregroundStyle(.green)
                        Text("Sparkilo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TripActivityElapsedView(state: context.state)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 60)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TripActivityBodyView(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(.green)
            } compactTrailing: {
                Text(compactFigure(context.state))
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    /// The one number worth the compact trailing slot: the station price
    /// during an approach, otherwise the live consumption figure.
    private func compactFigure(_ state: TripActivityAttributes.ContentState) -> String {
        if state.isApproach, let price = state.priceText { return price }
        return state.bigFigure
    }
}

/// Lock-screen / banner presentation.
struct TripActivityLockScreenView: View {
    let state: TripActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(.green)
                Text("Sparkilo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                TripActivityElapsedView(state: state)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            TripActivityBodyView(state: state)
        }
        .padding(14)
        .activityBackgroundTint(Color(.systemBackground).opacity(0.85))
    }
}

/// Elapsed readout: a natively ticking timer while recording, the
/// localized paused label while paused.
struct TripActivityElapsedView: View {
    let state: TripActivityAttributes.ContentState

    var body: some View {
        if state.paused {
            Text(state.pausedLabel)
        } else {
            Text(timerInterval: state.elapsedInterval, countsDown: false)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Shared body for the lock screen and the island's expanded bottom
/// region — the approach price lead or the consumption hero.
struct TripActivityBodyView: View {
    let state: TripActivityAttributes.ContentState

    var body: some View {
        if state.isApproach {
            approachBody
        } else {
            recordingBody
        }
    }

    /// Station-price lead (mirrors `TripRecordingPipPriceLayout`): huge
    /// price, fuel label, station + distance, closeness bar.
    private var approachBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(state.priceText ?? "--")
                    .font(.system(size: 34, weight: .heavy).monospacedDigit())
                if let fuel = state.fuelLabel {
                    Text(fuel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let dist = state.stationDistanceText {
                    Text(dist)
                        .font(.callout.weight(.semibold).monospacedDigit())
                }
            }
            if let station = state.stationName {
                Text(station)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
            }
            if let progress = state.progress {
                ProgressView(value: min(max(progress, 0), 1))
                    .progressViewStyle(.linear)
                    .tint(.green)
            }
        }
    }

    /// Consumption hero (mirrors the PiP default layout): huge figure,
    /// unit caption, distance secondary.
    private var recordingBody: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(state.bigFigure)
                .font(.system(size: 34, weight: .heavy).monospacedDigit())
            Text(state.bigCaption)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if let distance = state.distanceText {
                Text(distance)
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
