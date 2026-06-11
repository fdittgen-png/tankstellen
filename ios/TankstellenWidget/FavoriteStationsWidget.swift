// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Favorites widget (#3171) — Android parity for the favorites mode of
// `StationWidgetRenderer.kt`. Renders the user's favorite stations with
// their current prices from the `stations_json` payload
// `HomeWidgetService.updateWidget` writes on the same foreground
// heartbeat as the nearest payload (no extra wake-ups). Same
// `StationRow` JSON shape, so the shared decode + view do all the work.

import SwiftUI
import WidgetKit

struct FavoriteStationsProvider: TimelineProvider {
    typealias Entry = NearestStationsEntry

    func placeholder(in context: Context) -> Entry {
        NearestStationsEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> Void
    ) {
        completion(StationListPayload.timeline(for: currentEntry()))
    }

    private func currentEntry() -> Entry {
        StationListPayload.loadEntry(
            // The favorites payload (`HomeWidgetService.updateWidget`)
            // writes no empty-reason / stale keys — an empty list always
            // means "no favorites yet".
            jsonKey: "stations_json",
            emptyReasonKey: nil,
            staleKey: nil,
            noDataCopy: "Open Sparkilo to load your favorites",
            emptyListCopy: "Add favorite stations in Sparkilo to see them here"
        )
    }
}

struct FavoriteStationsWidget: Widget {
    let kind: String = "FavoriteStationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoriteStationsProvider()) { entry in
            StationListWidgetView(
                entry: entry,
                emptyFallback: "Add favorite stations in Sparkilo to see them here"
            )
        }
        .configurationDisplayName("Sparkilo — Favorites")
        .description("Your favorite fuel stations and their current prices.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
