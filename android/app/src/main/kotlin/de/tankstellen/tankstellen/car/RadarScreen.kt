// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import androidx.car.app.CarContext
import de.tankstellen.tankstellen.R

/**
 * Android Auto Radar screen. Renders the latest in-app radar result list
 * (written by Flutter to [CarStation.RADAR_KEY]) as a
 * [androidx.car.app.model.PlaceListMapTemplate].
 *
 * v2 SLICE 1 (#2947) wires only the Search screen to the LIVE headless
 * [CarDataBridge]; Radar STAYS on the v1 snapshot path
 * ([StationListScreen.liveFetchEnabled] left false) — its live fetch is slice
 * 2. The [kind] is set so slice 2 only flips `liveFetchEnabled` on.
 */
class RadarScreen(carContext: CarContext) : StationListScreen(carContext) {
    override val titleRes: Int = R.string.car_radar_title
    override val prefsKey: String = CarStation.RADAR_KEY
    override val emptyMessageRes: Int = R.string.car_empty_radar
    override val kind: CarFetchKind = CarFetchKind.RADAR
}
