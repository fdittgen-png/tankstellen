// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import androidx.car.app.CarContext
import de.tankstellen.tankstellen.R

/**
 * Android Auto v1 (#2948) — the car Radar screen. Renders the latest in-app
 * radar result list (written by Flutter to [CarStation.RADAR_KEY]) as a
 * [androidx.car.app.model.PlaceListMapTemplate].
 */
class RadarScreen(carContext: CarContext) : StationListScreen(carContext) {
    override val titleRes: Int = R.string.car_radar_title
    override val prefsKey: String = CarStation.RADAR_KEY
    override val emptyMessageRes: Int = R.string.car_empty_radar
}
