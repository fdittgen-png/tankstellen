// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// SwiftUI body for the Nearest-Stations widget.
//
// Renders one row per station with `widgetURL` set to the
// `tankstellenwidget://station?id=<id>` deep link so taps follow the
// same cold-start / warm-click flow Android uses (handled in the
// Flutter app by `WidgetClickListener` + the router's pending-URI
// redirect).
//
// Visual language deliberately matches the Android renderer: brand /
// street, price chip, distance pill. Keep both in lock-step so the
// user sees the same widget on both platforms.

import SwiftUI
import WidgetKit

struct NearestStationsWidgetView: View {
    let entry: NearestStationsEntry

    /// `.systemMedium` shows 3 rows, `.systemLarge` shows 5. Configurable
    /// via the widget family environment so the same body adapts.
    @Environment(\.widgetFamily) private var family

    private var maxRows: Int {
        switch family {
        case .systemLarge: return 5
        default: return 3
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemBackground)
            VStack(alignment: .leading, spacing: 6) {
                header
                if entry.rows.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(entry.rows.prefix(maxRows))) { row in
                        Link(destination: row.deepLink) {
                            StationRowView(row: row)
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

    private var header: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "fuelpump.fill")
                .foregroundStyle(.tint)
            Text("Sparkilo")
                .font(.caption.weight(.semibold))
            Spacer()
            if entry.isStale {
                Text("stale")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.orange.opacity(0.18))
                    )
                    .foregroundStyle(.orange)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.emptyReason ?? "No data yet")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StationRowView: View {
    let row: StationRow

    var body: some View {
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
                if let price = row.priceFormatted, !price.isEmpty {
                    Text(price)
                        .font(.callout.weight(.semibold))
                        .monospacedDigit()
                }
                if let distance = row.distanceKm {
                    Text(String(format: "%.1f km", distance))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }
}

private extension View {
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
