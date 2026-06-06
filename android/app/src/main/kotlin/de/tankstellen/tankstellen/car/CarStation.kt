// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Android Auto v1 (#2948 / epic #2946) — a single station the car Search /
 * Radar screens render, parsed from the JSON the Flutter app writes into the
 * shared [SharedPreferences] file (`HomeWidgetPreferences`).
 *
 * v1 reuses the home-widget SharedPreferences pipeline instead of a live
 * headless-engine bridge (deferred to the v2 rewrite, #2947). The Dart
 * `CarStationData` serializer is the source of truth for this shape; keep the
 * two in lock-step.
 */
data class CarStation(
    val id: String,
    val name: String,
    val brand: String,
    /**
     * Street + city subtitle (e.g. "Hauptstr. 1, 10115 Berlin"), or "" when the
     * station carries no address. Added in v2 phase-1 slice 3 (#2947) — old
     * address-less snapshots default it to "" (see [fromJson]), so they never
     * crash.
     */
    val address: String,
    val lat: Double,
    val lng: Double,
    /** Formatted selected-fuel price (3 dp), or "" when the fuel is unpriced. */
    val priceText: String,
    /** Language-neutral pump code, e.g. "E10", "Diesel". */
    val fuelLabel: String,
    /** cheap | aboveAverage | expensive | unknown. */
    val band: String,
    /** Cheap→expensive ramp colour as 0xAARRGGBB. */
    val bandColor: Int,
    val distanceKm: Double,
    val currency: String,
) {
    /** True when this station has a usable map anchor (real coordinates). */
    val hasLocation: Boolean
        get() = lat != 0.0 || lng != 0.0

    companion object {
        /** Prefs file the Flutter `home_widget` plugin writes to. */
        const val PREFS_NAME = "HomeWidgetPreferences"

        /** Key for the latest in-app search list (Dart `CarStationData.searchKey`). */
        const val SEARCH_KEY = "car_search_json"

        /** Key for the latest in-app radar list (Dart `CarStationData.radarKey`). */
        const val RADAR_KEY = "car_radar_json"

        /** Neutral grey for an unpriced station's map marker. */
        const val UNKNOWN_COLOR = 0xFF9E9E9E.toInt()

        /**
         * Read + parse the station list stored under [key]. Returns an empty
         * list when the key is missing, empty, or malformed — never throws, so
         * the car UI degrades to its empty-state message rather than crashing.
         */
        fun read(context: Context, key: String): List<CarStation> {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(key, null) ?: return emptyList()
            return parse(json)
        }

        /** Parse the car station JSON array. Malformed input → empty list. */
        fun parse(json: String): List<CarStation> {
            return try {
                val arr = JSONArray(json)
                val out = ArrayList<CarStation>(arr.length())
                for (i in 0 until arr.length()) {
                    val o = arr.optJSONObject(i) ?: continue
                    out.add(fromJson(o))
                }
                out
            } catch (e: Exception) {
                emptyList()
            }
        }

        private fun fromJson(o: JSONObject): CarStation = CarStation(
            id = o.optString("id", ""),
            name = o.optString("name", o.optString("brand", "Station")),
            brand = o.optString("brand", ""),
            // Back-compat: an old snapshot written before slice 3 has no
            // "address" key → optString returns "" (no subtitle), never throws.
            address = o.optString("address", ""),
            lat = o.optDouble("lat", 0.0),
            lng = o.optDouble("lng", 0.0),
            priceText = o.optString("priceText", ""),
            fuelLabel = o.optString("fuelLabel", ""),
            band = o.optString("band", "unknown"),
            bandColor = parseColor(o, "bandColor"),
            distanceKm = o.optDouble("distanceKm", 0.0),
            currency = o.optString("currency", ""),
        )

        /**
         * Read a 0xAARRGGBB colour int. JSON numbers above 0x7FFFFFFF arrive
         * as a `Long` (or `Double`) through `org.json`, so read as long and
         * narrow — `optInt` would clamp/overflow opaque colours.
         */
        private fun parseColor(o: JSONObject, name: String): Int {
            if (!o.has(name) || o.isNull(name)) return UNKNOWN_COLOR
            return o.optLong(name, UNKNOWN_COLOR.toLong()).toInt()
        }
    }
}
