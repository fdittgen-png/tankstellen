// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import androidx.car.app.CarContext
import de.tankstellen.tankstellen.R

/**
 * Android Auto v1 (#2948) — the car Search screen. Renders the latest in-app
 * search result list (written by Flutter to [CarStation.SEARCH_KEY]) as a
 * [androidx.car.app.model.PlaceListMapTemplate].
 */
class SearchScreen(carContext: CarContext) : StationListScreen(carContext) {
    override val titleRes: Int = R.string.car_search_title
    override val prefsKey: String = CarStation.SEARCH_KEY
    override val emptyMessageRes: Int = R.string.car_empty_search
}
