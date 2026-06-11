// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Predictive widget (#3171) — Android parity for the `predictive`
// content variant (#1121, `widget_variants.dart`). Android lets the user
// flip one widget between variants via the reconfigure activity; iOS
// `StaticConfiguration` has no such per-widget setting, so the predictive
// variant ships as its own gallery entry instead — the user picks
// "Sparkilo — Best time" when adding the widget.
//
// Data: reuses the nearest payload (`nearest_json`) — the Dart side
// attaches the per-row `predictive_*` fields there whenever the on-device
// price predictor has an actionable forecast, on the same refresh cadence
// as everything else. Rows without those fields render exactly like the
// default variant (same graceful fallback as the Kotlin renderer).

import SwiftUI
import WidgetKit

struct PredictiveStationsWidget: Widget {
    let kind: String = "PredictiveStationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NearestStationsProvider()) { entry in
            StationListWidgetView(
                entry: entry,
                emptyFallback: "No data yet",
                showPredictive: true
            )
        }
        .configurationDisplayName("Sparkilo — Best time")
        .description(
            "Nearby prices plus a hint for the cheapest time to fill up."
        )
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
