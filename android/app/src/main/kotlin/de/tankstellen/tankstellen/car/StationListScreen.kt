// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import android.location.Location
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
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

/**
 * Android Auto base car screen that renders a station list as a
 * [PlaceListMapTemplate]: the POI list on the left and the host-drawn map with
 * a coloured anchor per station on the right. Tapping a row pans/selects on the
 * map (standard `PlaceListMapTemplate` behaviour — no extra wiring needed).
 *
 * ## v1 snapshot vs v2 live SEARCH (#2947 / epic #2946)
 * v1 (#2948) renders the SharedPreferences snapshot the last in-app search /
 * radar wrote (`CarStation.read`). Slice 1 of v2 swaps the SEARCH data source
 * for a LIVE on-demand fetch via the headless [CarDataBridge]:
 *
 *  - `onGetTemplate` returns the snapshot IMMEDIATELY (instant, no blank) and
 *    kicks `CarDataBridge.fetch([kind])` when [liveFetchEnabled] is true.
 *  - On a live result it sets [liveStations] and calls [invalidate], which
 *    rebuilds the template from the live list.
 *  - The host Refresh button ([PlaceListMapTemplate.Builder.setOnContentRefreshListener])
 *    re-fetches; that callback is quota-exempt.
 *  - A cold start with an empty snapshot shows the loading state until the
 *    first live result; if no snapshot AND no live data arrive (e.g. a fresh
 *    Automotive head unit with no persisted fix) it shows [emptyMessageRes]
 *    (the no-GPS message for Search).
 *
 * Subclasses that stay on the v1 snapshot (Radar this slice) leave
 * [liveFetchEnabled] false. A missing/empty/malformed snapshot still degrades
 * to the friendly empty message (never crashes) — see [CarStation.read].
 */
abstract class StationListScreen(carContext: CarContext) : Screen(carContext) {

    /** Template title (a string resource id). */
    protected abstract val titleRes: Int

    /** SharedPreferences key holding this screen's snapshot station list. */
    protected abstract val prefsKey: String

    /** Empty-state message shown when there is no snapshot and no live data. */
    protected abstract val emptyMessageRes: Int

    /** Which list the live bridge fetches for this screen. */
    protected abstract val kind: CarFetchKind

    /**
     * Whether this screen fetches LIVE data via [liveSource]. Search opts in
     * (slice 1); Radar stays false (v1 snapshot, slice 2).
     */
    protected open val liveFetchEnabled: Boolean = false

    /**
     * The live data source. Defaults to the real [CarDataBridge]; overridable so
     * a Robolectric test can inject a fake (the real bridge wraps a
     * [io.flutter.embedding.engine.FlutterEngine] that can't run under
     * Robolectric).
     */
    protected open val liveSource: CarLiveSource = CarDataBridge

    /**
     * The live in-car fix feed (v2 phase-3 slice 4, #2990). Defaults to the
     * real [CarLocationSource]; overridable so a Robolectric test can inject a
     * fake (the real source wraps the platform LocationManager).
     */
    protected open val fixUpdates: CarFixUpdates = CarLocationSource

    /**
     * The latest LIVE list, or null before any live result has arrived. When
     * non-null it takes precedence over the snapshot in [onGetTemplate].
     * Mutated only on the main thread (the bridge callback), then [invalidate].
     */
    private var liveStations: List<CarStation>? = null

    /** True once a live fetch has completed (success OR fault). */
    private var liveAttempted = false

    /**
     * A first (or significantly-moved) live in-car fix arrived (#2990):
     * re-arm the fetch and invalidate so the next render searches around the
     * fresh position — this is what heals a cold-start `no_gps` empty-state
     * the moment the in-car GPS locks. Delivered on the main thread.
     */
    private val fixListener: (Location) -> Unit = {
        liveAttempted = false
        invalidate()
    }

    init {
        // Subscribe to live-fix updates only while this screen is visible and
        // only when it actually fetches live data.
        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStart(owner: LifecycleOwner) {
                if (liveFetchEnabled) fixUpdates.addListener(fixListener)
            }

            override fun onStop(owner: LifecycleOwner) {
                fixUpdates.removeListener(fixListener)
            }
        })
    }

    override fun onGetTemplate(): Template {
        val snapshot = CarStation.read(carContext, prefsKey)
        val stations = liveStations ?: snapshot

        // Capture the cold-start condition BEFORE kicking the fetch (which flips
        // liveAttempted): no snapshot AND no live result AND no fetch tried yet.
        val coldStart = liveFetchEnabled &&
            snapshot.isEmpty() && liveStations == null && !liveAttempted

        if (liveFetchEnabled && liveSource.isReady) {
            kickLiveFetch()
        }

        val builder = PlaceListMapTemplate.Builder()
            .setTitle(carContext.getString(titleRes))
            .setHeaderAction(Action.BACK)

        if (liveFetchEnabled) {
            // Host Refresh button — quota-exempt; re-fetch on demand.
            builder.setOnContentRefreshListener {
                liveAttempted = false
                kickLiveFetch(force = true)
            }
        }

        // A cold start (no snapshot, awaiting the first live result) shows the
        // host spinner. PlaceListMapTemplate forbids an item list while loading,
        // so set loading XOR the list — never both.
        if (coldStart && liveSource.isReady) {
            builder.setLoading(true)
        } else {
            val listBuilder = ItemList.Builder()
            if (stations.isEmpty()) {
                listBuilder.setNoItemsMessage(carContext.getString(emptyMessageRes))
            } else {
                for (station in stations) {
                    listBuilder.addItem(buildRow(station))
                }
            }
            builder.setItemList(listBuilder.build())
        }

        return builder.build()
    }

    /**
     * Kick a live fetch (idempotent within a render — the bridge's per-kind
     * re-entrancy guard collapses duplicate in-flight requests). On a JSON
     * result, parse + store it and [invalidate] so the next render shows the
     * live list; on null (timeout / fault / no fix) keep whatever is shown.
     */
    private fun kickLiveFetch(force: Boolean = false) {
        if (liveAttempted && !force) return
        liveAttempted = true
        liveSource.fetch(kind) { json ->
            if (json != null) {
                liveStations = CarStation.parse(json)
            }
            // Even on a null result, invalidate so a cold-start spinner clears
            // to the empty-state message rather than spinning forever.
            invalidate()
        }
    }

    private fun buildRow(station: CarStation): Row {
        val rowBuilder = Row.Builder().setTitle(station.title())

        // PlaceListMapTemplate rows allow at most two secondary text lines, so
        // pack price (with fuel label + currency) AND distance — via a
        // DistanceSpan the host renders in the user's locale unit — onto ONE
        // line, leaving the second line for the address subtitle (#2947 slice
        // 3). The address is rendered under the name, alongside price+distance.
        rowBuilder.addText(station.priceAndDistanceLine())
        if (station.address.isNotBlank()) {
            rowBuilder.addText(station.address)
        }

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

/**
 * One secondary line packing the price (with fuel label + currency) and the
 * distance — the distance rendered through a [DistanceSpan] so the head unit
 * shows it in the user's locale unit. Falls back to just the price when there
 * is no distance, or just the fuel label when the fuel is unpriced.
 */
private fun CarStation.priceAndDistanceLine(): CharSequence {
    val price = priceLine()
    if (distanceKm <= 0.0) return price

    // "<price>  ·  <distance>" — a single span placeholder anchors the
    // DistanceSpan, which the host replaces with the locale-formatted distance.
    val prefix = "$price  ·  "
    val builder = android.text.SpannableStringBuilder(prefix).append(" ")
    val span = DistanceSpan.create(
        Distance.create(distanceKm, Distance.UNIT_KILOMETERS)
    )
    builder.setSpan(span, prefix.length, builder.length, 0)
    return builder
}

/** Price line, e.g. "E10  1.799 €" — falls back to the fuel label alone. */
private fun CarStation.priceLine(): CharSequence {
    if (priceText.isEmpty()) return fuelLabel
    val cur = if (currency.isNotBlank()) " $currency" else ""
    return if (fuelLabel.isNotBlank()) "$fuelLabel  $priceText$cur" else "$priceText$cur"
}
