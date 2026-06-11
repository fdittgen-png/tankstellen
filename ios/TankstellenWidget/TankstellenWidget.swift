// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Widget extension bundle entry point.
//
// Registers the three station-list widgets (#3171 — Nearest, Favorites,
// Predictive; Android-parity for `StationWidgetRenderer.kt`'s modes +
// the #1121 predictive variant) and the trip Live Activity (#3170) with
// the WidgetKit runtime.
//
// Shape mirrors the Android `StationWidgetRenderer`'s row — same JSON
// contract under the shared App Group UserDefaults so a single Dart
// write path (`HomeWidgetService`) feeds both platforms. The `kind`
// strings here MUST stay in lock-step with `kIosWidgetKinds` in
// `lib/features/widget/data/impl/widget_reload_dispatcher.dart` — that
// list is what the Dart side reloads after every data write.

import SwiftUI
import WidgetKit

@main
struct TankstellenWidgetBundle: WidgetBundle {
    var body: some Widget {
        NearestStationsWidget()
        // #3171 — favorites + predictive variants (Android parity).
        FavoriteStationsWidget()
        PredictiveStationsWidget()
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
