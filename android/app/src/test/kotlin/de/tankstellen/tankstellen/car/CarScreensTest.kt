// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import android.content.Context
import androidx.car.app.Screen
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.PlaceListMapTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import de.tankstellen.tankstellen.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Android Auto v1 (#2948 / epic #2946) — JVM tests for the car screens.
 *
 * Drives the real `onGetTemplate()` through androidx.car.app's
 * [ScreenController] (moveToState → getTemplatesReturned) under Robolectric,
 * with station JSON seeded into the same SharedPreferences file the Flutter
 * app writes (`HomeWidgetPreferences`). Proves the menu has both rows, the
 * list screens render N place items from a seeded key, and a missing key shows
 * the empty-state message (never crashes).
 */
@RunWith(RobolectricTestRunner::class)
class CarScreensTest {

    private lateinit var carContext: TestCarContext

    @Before
    fun setUp() {
        carContext = TestCarContext.createCarContext(
            ApplicationProvider.getApplicationContext()
        )
        // Clean slate per test — no leftover car JSON from a prior test.
        carContext.getSharedPreferences(CarStation.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().clear().commit()
    }

    private fun seed(key: String, json: String) {
        carContext.getSharedPreferences(CarStation.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putString(key, json).commit()
    }

    /**
     * Register [screen] with the test car context (so its lifecycle +
     * ScreenManager are wired) and return the template it builds. `Screen`'s
     * `onGetTemplate()` is public in androidx.car.app 1.4.0, so we call it
     * directly — the host normally invokes it on render.
     */
    private fun templateOf(screen: Screen): Template {
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)
        return screen.onGetTemplate()
    }

    private fun string(resId: Int): String = carContext.getString(resId)

    private fun twoStationsJson(): String = """
        [
          {"id":"a","name":"Aral Hauptstr","brand":"Aral","lat":52.5,"lng":13.4,
           "price":1.799,"priceText":"1.799","fuelLabel":"E10","band":"cheap",
           "bandColor":4282621761,"distanceKm":1.2,"currency":"€"},
          {"id":"b","name":"Shell Bahnhof","brand":"Shell","lat":52.6,"lng":13.5,
           "price":1.899,"priceText":"1.899","fuelLabel":"E10","band":"expensive",
           "bandColor":4291176488,"distanceKm":3.4,"currency":"€"}
        ]
    """.trimIndent()

    @Test
    fun menuScreen_hasSearchAndRadarRows() {
        val template = templateOf(MenuScreen(carContext)) as ListTemplate

        val rows = (template.singleList as ItemList).items.filterIsInstance<Row>()
        assertEquals(2, rows.size)
        assertEquals(string(R.string.car_menu_search), rows[0].title.toString())
        assertEquals(string(R.string.car_menu_radar), rows[1].title.toString())
    }

    @Test
    fun searchScreen_rendersSeededStationsAsPlaceItems() {
        seed(CarStation.SEARCH_KEY, twoStationsJson())
        val template = templateOf(SearchScreen(carContext)) as PlaceListMapTemplate

        val rows = (template.itemList as ItemList).items.filterIsInstance<Row>()
        assertEquals(2, rows.size)
        assertEquals("Aral", rows[0].title.toString())
        // Each rendered station carries a map anchor (Place metadata).
        assertNotNull(rows[0].metadata?.place)
        assertNotNull(rows[1].metadata?.place)
    }

    @Test
    fun searchScreen_missingKeyShowsEmptyMessage() {
        // No seed → key absent.
        val template = templateOf(SearchScreen(carContext)) as PlaceListMapTemplate

        val list = template.itemList as ItemList
        assertTrue(list.items.isEmpty())
        assertEquals(string(R.string.car_empty_search), list.noItemsMessage.toString())
    }

    @Test
    fun radarScreen_rendersSeededStationsAndEmptyState() {
        // Empty first: missing key shows the radar empty message.
        var template = templateOf(RadarScreen(carContext)) as PlaceListMapTemplate
        var list = template.itemList as ItemList
        assertTrue(list.items.isEmpty())
        assertEquals(string(R.string.car_empty_radar), list.noItemsMessage.toString())

        // Seed → renders the stations.
        seed(CarStation.RADAR_KEY, twoStationsJson())
        template = templateOf(RadarScreen(carContext)) as PlaceListMapTemplate
        list = template.itemList as ItemList
        assertEquals(2, list.items.filterIsInstance<Row>().size)
    }

    @Test
    fun carStation_parsesContractAndDegradesOnMalformedJson() {
        val parsed = CarStation.parse(twoStationsJson())
        assertEquals(2, parsed.size)
        assertEquals("a", parsed[0].id)
        assertEquals("Aral", parsed[0].brand)
        assertEquals(52.5, parsed[0].lat, 0.0001)
        assertEquals("1.799", parsed[0].priceText)
        assertEquals("cheap", parsed[0].band)
        assertEquals(4282621761L.toInt(), parsed[0].bandColor)
        assertTrue(parsed[0].hasLocation)

        // Malformed input never throws — empty list.
        assertTrue(CarStation.parse("not json").isEmpty())
        assertTrue(CarStation.parse("").isEmpty())
    }
}
