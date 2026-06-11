// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// SwiftUI body for the Nearest-Stations widget — since #3171 a thin
// wrapper around the shared `StationListWidgetView` (the Favorites and
// Predictive variants render the same body off different payloads).
// Kept as its own type/file so the pbxproj reference and the widget's
// view name stay stable.

import SwiftUI
import WidgetKit

struct NearestStationsWidgetView: View {
    let entry: NearestStationsEntry

    var body: some View {
        StationListWidgetView(
            entry: entry,
            emptyFallback: "No data yet"
        )
    }
}
