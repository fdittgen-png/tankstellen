// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarLocation
import androidx.car.app.model.Distance
import androidx.car.app.model.DistanceSpan
import androidx.car.app.model.ItemList
import androidx.car.app.model.Metadata
import androidx.car.app.model.Place
import androidx.car.app.model.PlaceListMapTemplate
import androidx.car.app.model.PlaceMarker
import androidx.car.app.model.Row
import androidx.car.app.model.Template

/**
 * Android Auto v1 (#2948 / epic #2946) — base car screen that renders a
 * SharedPreferences-fed station list as a [PlaceListMapTemplate]: the POI list
 * on the left and the host-drawn map with a coloured anchor per station on the
 * right. Tapping a row pans/selects on the map (standard
 * `PlaceListMapTemplate` behaviour — no extra wiring needed).
 *
 * Subclasses supply the title, the SharedPreferences key, and the empty-state
 * message. A missing/empty/malformed key renders the friendly empty message
 * (never crashes) — see [CarStation.read].
 */
abstract class StationListScreen(carContext: CarContext) : Screen(carContext) {

    /** Template title (a string resource id). */
    protected abstract val titleRes: Int

    /** SharedPreferences key holding this screen's station list. */
    protected abstract val prefsKey: String

    /** Empty-state message shown when the key is missing/empty (string res id). */
    protected abstract val emptyMessageRes: Int

    override fun onGetTemplate(): Template {
        val stations = CarStation.read(carContext, prefsKey)
        val listBuilder = ItemList.Builder()

        if (stations.isEmpty()) {
            listBuilder.setNoItemsMessage(carContext.getString(emptyMessageRes))
        } else {
            for (station in stations) {
                listBuilder.addItem(buildRow(station))
            }
        }

        return PlaceListMapTemplate.Builder()
            .setTitle(carContext.getString(titleRes))
            .setHeaderAction(Action.BACK)
            .setItemList(listBuilder.build())
            .build()
    }

    private fun buildRow(station: CarStation): Row {
        val rowBuilder = Row.Builder().setTitle(station.title())

        // Subtitle: price (with fuel label + currency) then distance via a
        // DistanceSpan so the host renders the unit per the user's locale.
        rowBuilder.addText(station.priceLine())
        station.distanceText()?.let { rowBuilder.addText(it) }

        if (station.hasLocation) {
            val marker = PlaceMarker.Builder()
                .setColor(CarColor.createCustom(station.bandColor, station.bandColor))
                .build()
            val place = Place.Builder(CarLocation.create(station.lat, station.lng))
                .setMarker(marker)
                .build()
            rowBuilder.setMetadata(Metadata.Builder().setPlace(place).build())
        }

        return rowBuilder.build()
    }
}

/** Row title: prefer the brand, fall back to the station name. */
private fun CarStation.title(): String =
    if (brand.isNotBlank()) brand else name

/** Price line, e.g. "E10  1.799 €" — falls back to the fuel label alone. */
private fun CarStation.priceLine(): CharSequence {
    if (priceText.isEmpty()) return fuelLabel
    val cur = if (currency.isNotBlank()) " $currency" else ""
    return if (fuelLabel.isNotBlank()) "$fuelLabel  $priceText$cur" else "$priceText$cur"
}

/**
 * Distance rendered as a [DistanceSpan] so the head unit shows it in the
 * user's locale units. Returns null when no distance is known.
 */
private fun CarStation.distanceText(): CharSequence? {
    if (distanceKm <= 0.0) return null
    val builder = android.text.SpannableString(" ")
    val span = DistanceSpan.create(
        Distance.create(distanceKm, Distance.UNIT_KILOMETERS)
    )
    builder.setSpan(span, 0, builder.length, 0)
    return builder
}
