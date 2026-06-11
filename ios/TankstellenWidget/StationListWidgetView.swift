// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Shared SwiftUI body for the station-list widgets (#3171): the Nearest,
// Favorites and Predictive variants all render this view — only the entry
// source and the `showPredictive` flag differ.
//
// Renders one row per station with `widgetURL` set to the
// `tankstellenwidget://station?id=<id>` deep link so taps follow the
// same cold-start / warm-click flow Android uses (handled in the
// Flutter app by `WidgetClickListener` + the router's pending-URI
// redirect).
//
// Visual language deliberately matches the Android renderer: brand /
// street, price chip (green on the cheapest row, #2600), distance pill,
// optional predictive "best time to fill" second line (#1121). Keep both
// in lock-step so the user sees the same widget on both platforms.
//
// Localization: dynamic strings arrive pre-localized / pre-formatted from
// the Dart side via the App-Group payload; the literals here are the
// brand name and static fallback copy (same convention as
// `TripRecordingLiveActivity`).

import AppIntents
import SwiftUI
import WidgetKit

struct StationListWidgetView: View {
    let entry: NearestStationsEntry
    /// Copy for the empty state when the entry carries no reason of its own.
    let emptyFallback: String
    /// #1121 / #3171 — when true, rows with Dart-attached `predictive_*`
    /// fields render the compact "best time to fill" second line; rows
    /// without them keep the default appearance (same per-row fallback as
    /// the Android VARIANT_PREDICTIVE).
    var showPredictive: Bool = false

    /// `.systemMedium` shows 3 rows, `.systemLarge` shows 5 (one less in
    /// predictive mode — the second line costs vertical space).
    @Environment(\.widgetFamily) private var family

    private var maxRows: Int {
        let base = family == .systemLarge ? 5 : 3
        return showPredictive ? max(base - 1, 1) : base
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemBackground)
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeaderView(isStale: entry.isStale)
                if entry.rows.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(entry.rows.prefix(maxRows))) { row in
                        Link(destination: row.deepLink) {
                            StationRowView(
                                row: row,
                                showPredictive: showPredictive
                            )
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .widgetURL(
            // Fallback tap target for the whole widget (system small +
            // any tap that misses an individual Link). Routes to the
            // search screen via a sentinel URI the parser ignores —
            // the app's redirect chain falls through to its normal
            // landing without trying to open a station detail.
            URL(string: "tankstellenwidget://station?id=__widget_root__")
        )
        .widgetBackgroundCompat()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.emptyReason ?? emptyFallback)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Shared header chrome: brand mark, optional stale pill, and — on
/// iOS 17+ — the interactive AppIntent refresh button (#3171). On iOS 16
/// the button is simply absent (interactive widgets are an iOS 17
/// feature; the widget still refreshes on its own timeline policy).
struct WidgetHeaderView: View {
    let isStale: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "fuelpump.fill")
                .foregroundStyle(.tint)
            Text("Sparkilo")
                .font(.caption.weight(.semibold))
            Spacer()
            if isStale {
                Text("stale")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.orange.opacity(0.18))
                    )
                    .foregroundStyle(.orange)
            }
            if #available(iOSApplicationExtension 17.0, *) {
                Button(intent: WidgetRefreshIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StationRowView: View {
    let row: StationRow
    var showPredictive: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.displayName)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    if let street = row.street, street != row.displayName {
                        Text(street)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let price = row.displayPrice {
                        Text(price)
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                            // #2600 parity — the cheapest row's price is
                            // green, like the Android renderer's
                            // widget_price_cheap.
                            .foregroundStyle(
                                row.isCheapest == true
                                    ? AnyShapeStyle(.green)
                                    : AnyShapeStyle(.primary)
                            )
                    }
                    if let distance = row.distanceKm {
                        Text(String(format: "%.1f km", distance))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            if showPredictive, let line = row.predictiveLine {
                Text(line)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

extension View {
    /// iOS 17 requires widgets to adopt `containerBackground(for: .widget)`
    /// — without it WidgetKit renders a "Please adopt containerBackground
    /// API" placeholder instead of the widget content. On iOS 16 (our
    /// deployment target is 16.6) the in-view ZStack background above is
    /// still the rendering path, so the shim is a no-op there.
    @ViewBuilder
    func widgetBackgroundCompat() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                Color(.systemBackground)
            }
        } else {
            self
        }
    }
}
