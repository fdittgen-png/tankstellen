// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import androidx.car.app.CarContext
import de.tankstellen.tankstellen.R

/**
 * Android Auto Radar screen, now fed by a LIVE on-demand fetch through the
 * headless [CarDataBridge] (v2 phase-1 slice 2, #2947) — it was the v1
 * SharedPreferences snapshot before.
 *
 * `onGetTemplate` (in [StationListScreen]) returns the `car_radar_json`
 * snapshot immediately for an instant, never-blank first frame, then kicks
 * `CarDataBridge.fetch(RADAR)` and rebuilds from the live list when it arrives
 * (the nearest priced stations within the active-profile radius, distance-
 * sorted). With no snapshot AND no live data (a fresh head unit with no
 * persisted GPS fix) it shows the `car_empty_no_gps` message — never crashes.
 * An empty live result keeps the existing snapshot.
 */
class RadarScreen(carContext: CarContext) : StationListScreen(carContext) {
    override val titleRes: Int = R.string.car_radar_title
    override val prefsKey: String = CarStation.RADAR_KEY
    override val emptyMessageRes: Int = R.string.car_empty_no_gps
    override val kind: CarFetchKind = CarFetchKind.RADAR
    override val liveFetchEnabled: Boolean = true
}
