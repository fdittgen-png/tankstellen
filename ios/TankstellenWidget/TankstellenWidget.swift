// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Widget extension bundle entry point.
//
// Defines the Nearest-Stations widget and registers it with the WidgetKit
// runtime. Pair widget for the Cheapest / Favourites variant can be added
// alongside `NearestStationsWidget` inside the `WidgetBundle` body once a
// dedicated provider lands.
//
// Shape mirrors the Android `StationWidgetRenderer`'s NearestStations row
// — same JSON contract under the shared App Group UserDefaults so a single
// Dart write path (`HomeWidgetService.updateWidget`) feeds both platforms.

import SwiftUI
import WidgetKit

@main
struct TankstellenWidgetBundle: WidgetBundle {
    var body: some Widget {
        NearestStationsWidget()
        // #3170 — trip-recording / approach-radar Live Activity
        // (Dynamic Island + lock screen), driven by the Runner-side
        // LiveActivityBridge over `tankstellen/live_activity`.
        TripRecordingLiveActivity()
    }
}

struct NearestStationsWidget: Widget {
    let kind: String = "NearestStationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NearestStationsProvider()) { entry in
            NearestStationsWidgetView(entry: entry)
        }
        .configurationDisplayName("Sparkilo — Nearest")
        .description("Closest fuel stations and their current prices.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#if DEBUG
struct NearestStationsWidget_Previews: PreviewProvider {
    static var previews: some View {
        NearestStationsWidgetView(entry: NearestStationsEntry.placeholder)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
