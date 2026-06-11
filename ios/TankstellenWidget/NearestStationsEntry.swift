// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// TimelineEntry payload shared by every station-list widget in the bundle
// (#3171): Nearest reads `nearest_json`, Favorites reads `stations_json`,
// Predictive reuses the nearest payload.
//
// `rows` is the parsed station array (see `StationRow`). `isStale`
// reflects the `nearest_is_stale` flag the Dart side sets when the data
// is older than the freshness budget — the SwiftUI view renders a small
// "stale" pill when this is true so the user knows the prices may have
// moved since the last sync (always false for the favorites payload,
// which has no stale concept).

import Foundation
import WidgetKit

struct NearestStationsEntry: TimelineEntry {
    let date: Date
    let rows: [StationRow]
    let isStale: Bool
    let emptyReason: String?

    /// Placeholder used by `placeholder(in:)` and SwiftUI previews when
    /// the App Group container is empty (e.g. before the host app has
    /// run once, or while a fresh install is still downloading prices).
    static let placeholder = NearestStationsEntry(
        date: Date(),
        rows: (1...3).map { i in
            StationRow(
                id: "placeholder-\(i)",
                brand: "Sparkilo",
                name: nil,
                street: "Loading…",
                postCode: nil,
                place: nil,
                e5: nil,
                e10: nil,
                diesel: nil,
                preferredFuelCode: nil,
                preferredFuelPrice: nil,
                distanceKm: Double(i),
                isOpen: true,
                currency: "€",
                priceFormatted: "—",
                isCheapest: false,
                predictiveBestLabel: nil,
                predictiveBestPrice: nil
            )
        },
        isStale: false,
        emptyReason: nil
    )

    /// Fallback rendered when the App Group container reports an empty
    /// `nearest_json`. The view shows `emptyReason` verbatim so the
    /// user knows why ("no GPS fix", "no nearby stations", etc.) —
    /// matches the Android empty-state copy.
    static func empty(reason: String) -> NearestStationsEntry {
        NearestStationsEntry(
            date: Date(),
            rows: [],
            isStale: false,
            emptyReason: reason
        )
    }
}
