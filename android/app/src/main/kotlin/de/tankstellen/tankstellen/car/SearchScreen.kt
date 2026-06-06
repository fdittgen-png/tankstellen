// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import androidx.car.app.CarContext
import de.tankstellen.tankstellen.R

/**
 * Android Auto v2 SLICE 1 (#2947) — the car Search screen, now fed by a LIVE
 * on-demand fetch through the headless [CarDataBridge] (it was the v1
 * SharedPreferences snapshot before, #2948).
 *
 * `onGetTemplate` (in [StationListScreen]) returns the snapshot immediately for
 * an instant, never-blank first frame, then kicks `CarDataBridge.fetch(SEARCH)`
 * and rebuilds from the live list when it arrives. With no snapshot AND no live
 * data (a fresh Automotive head unit with no persisted GPS fix) it shows the
 * `car_empty_no_gps` message — never crashes.
 */
class SearchScreen(carContext: CarContext) : StationListScreen(carContext) {
    override val titleRes: Int = R.string.car_search_title
    override val prefsKey: String = CarStation.SEARCH_KEY
    override val emptyMessageRes: Int = R.string.car_empty_no_gps
    override val kind: CarFetchKind = CarFetchKind.SEARCH
    override val liveFetchEnabled: Boolean = true
}
